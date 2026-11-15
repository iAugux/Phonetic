import Contacts
import Foundation
import os
import OSLog

private let historyLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.iAugus.Phonetic", category: "ContactVersionHistory")

private func historyFailure(_ operation: String, error: Error) -> ContactVersionError {
    let failure = error as NSError
    // Log the stage and error code without contact values or container paths.
    historyLogger.error("\(operation, privacy: .public) failed: \(failure.domain, privacy: .public) (\(failure.code))")
    return .historyUnavailable
}

private struct VersionManifest: Codable {
    let schema: Int
    var version: ContactVersion
}

private struct VersionWrite: Codable {
    let sequence: Int
    var confirmed: Bool
    var changes: [ContactVersionChange]
}

private struct HistoryBoundary: Codable {
    let schema: Int
    let earliestOrdinal: Int
}

private struct HistorySpaceNeeded: Error {
    let bytes: Int64
}

struct ContactVersionEdit: Sendable {
    let changes: [ContactVersionChange]
    let expected: [ContactVersionField: ContactVersionValue]
}

private func historyFileSize(_ url: URL) throws -> Int64 {
    let values = try url.resourceValues(forKeys: [.fileSizeKey, .totalFileAllocatedSizeKey])
    guard let logical = values.fileSize else { throw ContactVersionError.historyUnavailable }
    return Int64(max(logical, values.totalFileAllocatedSize ?? logical))
}

@discardableResult
private func writeHistory<T: Encodable>(_ value: T, to url: URL, newFileBudget: Int64? = nil) throws -> Int64 {
    let data = try JSONEncoder().encode(value)
    if let newFileBudget {
        guard !FileManager.default.fileExists(atPath: url.path) else { throw ContactVersionError.historyUnavailable }
        guard Int64(data.count) <= newFileBudget else { throw HistorySpaceNeeded(bytes: Int64(data.count)) }
    }
    try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    let size = try historyFileSize(url)
    if let newFileBudget, size > newFileBudget {
        // Allocation can exceed the encoded size. Reject and remove the intent before Contacts saves.
        try FileManager.default.removeItem(at: url)
        throw HistorySpaceNeeded(bytes: size)
    }
    return size
}

private let historyNameFields: [ContactVersionField] = [.givenName, .familyName, .namePrefix, .nameSuffix, .organizationName, .nickname]

private func historyContactName(_ contact: CNContact) -> String? {
    // Batch fetches omit some formatter keys. Copy available values into a fully available contact.
    let displayContact = CNMutableContact()
    let textKeys = historyNameFields.map(\.key) + [CNContactMiddleNameKey]
    for key in textKeys + [CNContactTypeKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey] where contact.isKeyAvailable(key) {
        displayContact.setValue(contact.value(forKey: key), forKey: key)
    }
    let hasText = textKeys.contains { key in
        (displayContact.value(forKey: key) as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
    guard hasText || !displayContact.phoneNumbers.isEmpty || !displayContact.emailAddresses.isEmpty else { return nil }
    return displayContact.whitelistDisplayName
}

/// A session has one serial writer. The lock also prevents use after finalization.
final class ContactVersionSession: Sendable {
    let id: UUID
    fileprivate let folder: URL
    private let source: any ContactVersionSource
    private let reclaimSpace: @Sendable (Int64) throws -> Int64
    fileprivate let restoreTarget: Int?
    fileprivate let restoreHead: UUID?
    private let state: OSAllocatedUnfairLock<(sequence: Int, closed: Bool, availableBytes: Int64)>

    fileprivate init(id: UUID, folder: URL, source: any ContactVersionSource, availableBytes: Int64, restoreTarget: Int?, restoreHead: UUID?, reclaimSpace: @escaping @Sendable (Int64) throws -> Int64) {
        self.id = id
        self.folder = folder
        self.source = source
        self.restoreTarget = restoreTarget
        self.restoreHead = restoreHead
        self.reclaimSpace = reclaimSpace
        state = OSAllocatedUnfairLock(initialState: (sequence: 0, closed: false, availableBytes: availableBytes))
    }

    func save(original: CNContact, modified: CNContact) throws {
        let edit = try Self.edit(original: original, modified: modified)
        try save(edit.changes, expected: edit.expected)
    }

    static func edit(original: CNContact, modified: CNContact) throws -> ContactVersionEdit {
        let displayName = historyContactName(original) ?? String(localized: "Unnamed Contact")
        let changes = try ContactVersionField.allCases.compactMap { field -> ContactVersionChange? in
            guard original.isKeyAvailable(field.key), modified.isKeyAvailable(field.key) else { return nil }
            let before = try ContactVersionValue.read(field, from: original)
            let after = try ContactVersionValue.read(field, from: modified)
            guard before != after else { return nil }
            return ContactVersionChange(contactID: original.identifier, contactName: displayName,
                                        field: field, before: before, after: after)
        }
        guard !changes.isEmpty else { return ContactVersionEdit(changes: [], expected: [:]) }
        let expected = try Dictionary(uniqueKeysWithValues: ContactVersionField.allCases.filter { original.isKeyAvailable($0.key) }.map {
            ($0, try ContactVersionValue.read($0, from: original))
        })
        return ContactVersionEdit(changes: changes, expected: expected)
    }

    func save(_ changes: [ContactVersionChange], expected: [ContactVersionField: ContactVersionValue] = [:]) throws {
        guard !changes.isEmpty else { return }
        try state.withLock { state in
            guard !state.closed else { throw ContactVersionError.busy }
            var mutable = try mutableContact(for: changes, expected: expected)
            state.sequence += 1
            let url = folder.appendingPathComponent("\(state.sequence)-\(UUID().uuidString).json")
            var write = VersionWrite(sequence: state.sequence, confirmed: false, changes: changes)
            // Persist intent before touching Contacts. An interrupted save can be reconciled on launch.
            var preparedSize: Int64 = 0
            while true {
                do {
                    preparedSize = try writeHistory(write, to: url, newFileBudget: state.availableBytes)
                    state.availableBytes -= preparedSize
                    break
                } catch let needed as HistorySpaceNeeded {
                    let available: Int64
                    do { available = try reclaimSpace(max(needed.bytes, state.availableBytes + 1)) }
                    catch let error as ContactVersionError { throw error }
                    catch { throw historyFailure("Reclaim history space", error: error) }
                    guard available > state.availableBytes else { throw ContactVersionError.storageLimitReached }
                    state.availableBytes = available
                    // Cleanup may take time; recheck external edits before persisting and saving this change.
                    mutable = try mutableContact(for: changes, expected: expected)
                } catch let error as ContactVersionError { throw error }
                catch { throw historyFailure("Persist change intent", error: error) }
            }
            do { try source.save(mutable) } catch { throw ContactVersionError.saveFailed }
            do {
                write = try Self.resolve(write, source: source)
                let confirmedSize = try writeHistory(write, to: url)
                state.availableBytes += preparedSize - confirmedSize
            } catch { throw historyFailure("Confirm contact write", error: error) }
            guard write.changes.count == changes.count, !write.changes.contains(where: \.uncertain) else { throw ContactVersionError.contactsChanged }
        }
    }

    private func mutableContact(for changes: [ContactVersionChange], expected: [ContactVersionField: ContactVersionValue]) throws -> CNMutableContact {
        let fields = Array(Set(changes.map(\.field) + Array(expected.keys)))
        guard let first = changes.first,
              changes.allSatisfy({ $0.contactID == first.contactID }),
              let current = try source.read(identifier: first.contactID, fields: fields),
              let mutable = current.mutableCopy() as? CNMutableContact else { throw ContactVersionError.contactsChanged }
        for (field, value) in expected {
            guard try ContactVersionValue.read(field, from: current) == value else { throw ContactVersionError.contactsChanged }
        }
        for change in changes {
            guard try ContactVersionValue.read(change.field, from: current) == change.before else { throw ContactVersionError.contactsChanged }
            try change.after.apply(change.field, to: mutable)
        }
        return mutable
    }

    fileprivate func close() { state.withLock { $0.closed = true } }

    fileprivate static func resolve(_ write: VersionWrite, source: any ContactVersionSource) throws -> VersionWrite {
        guard !write.confirmed, let first = write.changes.first else { return write }
        let current = try source.read(identifier: first.contactID, fields: write.changes.map(\.field))
        var resolved = write
        resolved.changes = try write.changes.compactMap { change in
            guard let current else {
                var change = change
                change.uncertain = true
                return change
            }
            let value = try ContactVersionValue.read(change.field, from: current)
            if value == change.before { return nil }
            var change = change
            change.uncertain = value != change.after
            return change
        }
        resolved.confirmed = true
        return resolved
    }
}

actor ContactVersionStore {
    static let defaultByteLimit: Int64 = 100_000_000
    // Successful Contacts writes must still have room to finalize their version metadata.
    private static let finalizationReserve: Int64 = 16_384
    static let shared = ContactVersionStore(
        root: URL.applicationSupportDirectory.appendingPathComponent("ContactVersions", isDirectory: true),
        source: SystemContactVersionSource())

    private let root: URL
    private let source: any ContactVersionSource
    private let byteLimit: Int64
    private var active: UUID?

    init(root: URL, source: any ContactVersionSource, byteLimit: Int64 = ContactVersionStore.defaultByteLimit) {
        self.root = root.resolvingSymlinksInPath()
        self.source = source
        self.byteLimit = max(1, byteLimit)
    }

    func versions() throws -> [ContactVersion] {
        guard active == nil else { throw ContactVersionError.busy }
        try prepare()
        try maintainStorage()
        return try manifests().map(\.version).sorted { $0.ordinal > $1.ordinal }
    }

    func overview() throws -> ContactVersionHistory {
        guard active == nil else { throw ContactVersionError.busy }
        try prepare()
        try maintainStorage()
        return ContactVersionHistory(versions: try manifests().map(\.version).sorted { $0.ordinal > $1.ordinal },
                                     usedBytes: try storageUsed(), limitBytes: byteLimit, earliestOrdinal: try boundary().earliestOrdinal)
    }

    func begin(kind: ContactVersionKind, targetOrdinal: Int? = nil, expectedHead: UUID? = nil, checkHead: Bool = false) throws -> ContactVersionSession {
        guard active == nil else { throw ContactVersionError.busy }
        guard source.hasAccess() else { throw ContactVersionError.accessNeeded }
        try prepare()
        let versions = try manifests().map(\.version)
        let head = versions.max { $0.ordinal < $1.ordinal }
        if checkHead, head?.id != expectedHead { throw ContactVersionError.historyChanged }
        if kind == .restore, !checkHead || targetOrdinal == nil { throw ContactVersionError.historyChanged }
        let earliest = try boundary().earliestOrdinal
        if let targetOrdinal, targetOrdinal != earliest && !versions.contains(where: { $0.ordinal == targetOrdinal }) {
            throw ContactVersionError.historyChanged
        }
        // Defer eviction until a real contact change needs space; no-op jobs keep older history.
        let available = byteLimit - (try storageUsed()) - Self.finalizationReserve
        let version = ContactVersion(id: UUID(), ordinal: (head?.ordinal ?? earliest) + 1, createdAt: Date(), kind: kind,
                                     targetOrdinal: targetOrdinal, status: .pending, contactCount: 0, fieldCount: 0)
        let folder = directory(version.id)
        let manifestSize: Int64
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false,
                                                    attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
            manifestSize = try writeHistory(VersionManifest(schema: 1, version: version), to: folder.appendingPathComponent("manifest.json"))
        } catch let error as ContactVersionError {
            try? FileManager.default.removeItem(at: folder)
            throw error
        } catch {
            try? FileManager.default.removeItem(at: folder)
            throw historyFailure("Create version", error: error)
        }
        active = version.id
        return ContactVersionSession(id: version.id, folder: folder, source: source, availableBytes: available - manifestSize,
                                     restoreTarget: kind == .restore ? targetOrdinal : nil, restoreHead: expectedHead,
                                     reclaimSpace: { try self.makeRoom(minimumAvailable: $0, excluding: version.id) })
    }

    func finish(_ session: ContactVersionSession, outcome: ContactOperationOutcome) throws {
        guard active == session.id else { throw ContactVersionError.busy }
        session.close()
        defer { active = nil }
        let status: ContactVersionStatus
        switch outcome {
        case .completed: status = .completed
        case .stopped: status = .stopped
        case .failed: status = .failed
        }
        do { try finalize(folder: session.folder, status: status) } catch { throw historyFailure("Finalize version", error: error) }
    }

    func saveEdit(_ edit: ContactVersionEdit, session: ContactVersionSession) throws {
        guard active == session.id else { throw ContactVersionError.busy }
        try session.save(edit.changes, expected: edit.expected)
    }

    func preview(targetOrdinal: Int) throws -> ContactRestorePreview {
        guard active == nil else { throw ContactVersionError.busy }
        guard source.hasAccess() else { throw ContactVersionError.accessNeeded }
        try prepare()
        try maintainStorage()
        let versions = try manifests().map(\.version).sorted { $0.ordinal > $1.ordinal }
        guard targetOrdinal == (try boundary().earliestOrdinal) || versions.contains(where: { $0.ordinal == targetOrdinal }) else { throw ContactVersionError.historyChanged }
        var folded: [String: ContactVersionChange] = [:]
        for version in versions where version.ordinal > targetOrdinal {
            for write in try writes(in: directory(version.id)).sorted(by: { $0.sequence > $1.sequence }) {
                for change in write.changes {
                    if let later = folded[change.id] {
                        folded[change.id] = ContactVersionChange(contactID: change.contactID, contactName: change.contactName,
                                                                 field: change.field, before: change.before, after: later.after,
                                                                 uncertain: change.uncertain || later.uncertain || change.after != later.before)
                    } else { folded[change.id] = change }
                }
            }
        }
        var entries: [ContactRestoreEntry] = []
        let groups = Dictionary(grouping: folded.values.filter { $0.before != $0.after || $0.uncertain }, by: \.contactID)
        for (identifier, changes) in groups {
            let fields = Array(Set(changes.map(\.field) + historyNameFields))
            let current = try source.read(identifier: identifier, fields: fields)
            let displayName = current.flatMap(historyContactName)
            for change in changes {
                let value = try current.map { try ContactVersionValue.read(change.field, from: $0) }
                if value == change.before { continue }
                let displayChange = ContactVersionChange(contactID: change.contactID, contactName: displayName ?? change.contactName,
                                                         field: change.field, before: change.before, after: change.after, uncertain: change.uncertain)
                entries.append(ContactRestoreEntry(change: displayChange, current: value, isConflict: change.uncertain || value != change.after))
            }
        }
        entries.sort { ($0.change.contactName, $0.change.contactID, $0.change.field.rawValue) < ($1.change.contactName, $1.change.contactID, $1.change.field.rawValue) }
        return ContactRestorePreview(headID: versions.first?.id, targetOrdinal: targetOrdinal, entries: entries)
    }

    /// Revalidate the preview immediately before each contact write; never force a stale preview.
    func restore(_ preview: ContactRestorePreview, selected: Set<String>, session: ContactVersionSession,
                 shouldStop: @Sendable () -> Bool, progress: @Sendable (Int, Int) -> Void) throws -> Int {
        guard active == session.id else { throw ContactVersionError.busy }
        // Retention may advance the boundary after validation. The immutable preview remains authorized.
        guard session.restoreTarget == preview.targetOrdinal, session.restoreHead == preview.headID else { throw ContactVersionError.historyChanged }
        let groups = Dictionary(grouping: preview.entries.filter { selected.contains($0.id) && $0.current != nil }, by: { $0.change.contactID })
        var skipped = 0
        var checked = 0
        for (identifier, entries) in groups.sorted(by: { $0.key < $1.key }) {
            if shouldStop() { break }
            let current = try source.read(identifier: identifier, fields: entries.map { $0.change.field })
            var changes: [ContactVersionChange] = []
            for entry in entries {
                guard let current, let expected = entry.current,
                      try ContactVersionValue.read(entry.change.field, from: current) == expected else { skipped += 1; continue }
                changes.append(ContactVersionChange(contactID: identifier, contactName: entry.change.contactName,
                                                    field: entry.change.field, before: expected, after: entry.change.before))
            }
            try session.save(changes)
            checked += 1
            progress(checked, groups.count)
        }
        return skipped
    }

    private func prepare() throws {
        do {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true,
                                                    attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
            var resourceURL = root
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try resourceURL.setResourceValues(values)
            try removeDiscardedHistory()
            for manifest in try manifests() where manifest.version.status == .pending && manifest.version.id != active {
                guard source.hasAccess() else { throw ContactVersionError.accessNeeded }
                try finalize(folder: directory(manifest.version.id), status: .interrupted)
            }
        } catch let error as ContactVersionError { throw error }
        catch { throw historyFailure("Prepare or recover history", error: error) }
    }

    private func maintainStorage() throws {
        guard try storageUsed() > byteLimit else { return }
        do { _ = try makeRoom(minimumAvailable: 0) }
        catch ContactVersionError.storageLimitReached { /* Oversized retained history must remain readable. */ }
    }

    // Idle calls are serialized by the actor. During a job, only its locked session calls this callback;
    // idle store entry points reject work, and finalization waits until its writer has stopped.
    nonisolated private func makeRoom(minimumAvailable: Int64, excluding activeID: UUID? = nil) throws -> Int64 {
        let used = try storageUsed()
        let available = byteLimit - used - Self.finalizationReserve
        guard available < minimumAvailable else { return available }
        let candidates = try manifests().sorted { $0.version.ordinal < $1.version.ordinal }
            .prefix { $0.version.id != activeID && $0.version.status != .pending }
        var costs: [(version: ContactVersion, bytes: Int64)] = []
        for candidate in candidates {
            costs.append((candidate.version, try storageUsed(in: directory(candidate.version.id))))
        }
        let reclaimable = costs.reduce(Int64(0)) { $0 + $1.bytes }
        let boundaryReserve = FileManager.default.fileExists(atPath: boundaryURL.path) ? 0 : Self.finalizationReserve
        // An operation too large even after cleanup must not discard useful history pointlessly.
        guard !costs.isEmpty, byteLimit - (used - reclaimable) - Self.finalizationReserve - boundaryReserve >= minimumAvailable else {
            throw ContactVersionError.storageLimitReached
        }
        let target = min(byteLimit - byteLimit / 5, byteLimit - Self.finalizationReserve - boundaryReserve - minimumAvailable)
        var projected = used
        var cutoff: Int?
        for candidate in costs {
            guard projected > target else { break }
            projected -= candidate.bytes
            cutoff = candidate.version.ordinal
        }
        guard let cutoff else { throw ContactVersionError.storageLimitReached }
        do {
            try writeHistory(HistoryBoundary(schema: 1, earliestOrdinal: cutoff), to: boundaryURL)
            try removeDiscardedHistory()
        } catch { throw historyFailure("Automatically remove older history", error: error) }
        return try makeRoom(minimumAvailable: minimumAvailable, excluding: activeID)
    }

    nonisolated private func directory(_ id: UUID) -> URL { root.appendingPathComponent(id.uuidString, isDirectory: true) }

    nonisolated private var boundaryURL: URL { root.appendingPathComponent(".boundary.json") }
    nonisolated private var discardedURL: URL { root.appendingPathComponent(".discarded", isDirectory: true) }

    nonisolated private func boundary() throws -> HistoryBoundary {
        guard FileManager.default.fileExists(atPath: boundaryURL.path) else { return HistoryBoundary(schema: 1, earliestOrdinal: 0) }
        let value = try JSONDecoder().decode(HistoryBoundary.self, from: Data(contentsOf: boundaryURL))
        guard value.schema == 1, value.earliestOrdinal >= 0 else { throw ContactVersionError.historyUnavailable }
        return value
    }

    nonisolated private func removeDiscardedHistory() throws {
        let earliest = try boundary().earliestOrdinal
        let older = try manifests().filter { $0.version.ordinal <= earliest }
        if !older.isEmpty {
            try FileManager.default.createDirectory(at: discardedURL, withIntermediateDirectories: true,
                                                    attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
            for manifest in older {
                try FileManager.default.moveItem(at: directory(manifest.version.id), to: discardedURL.appendingPathComponent(manifest.version.id.uuidString))
            }
        }
        if FileManager.default.fileExists(atPath: discardedURL.path) {
            try FileManager.default.removeItem(at: discardedURL)
        }
    }

    nonisolated private func storageUsed(in directory: URL? = nil) throws -> Int64 {
        var scanError: Error?
        guard let files = FileManager.default.enumerator(at: directory ?? root, includingPropertiesForKeys: [.isRegularFileKey], options: [], errorHandler: { _, error in
            scanError = error
            return false
        }) else { throw ContactVersionError.historyUnavailable }
        var bytes: Int64 = 0
        for case let file as URL in files {
            if try file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true { bytes += try historyFileSize(file) }
        }
        if let scanError { throw scanError }
        return bytes
    }

    nonisolated private func manifests() throws -> [VersionManifest] {
        try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil, options: .skipsHiddenFiles).compactMap { folder in
            let manifestURL = folder.appendingPathComponent("manifest.json")
            if !FileManager.default.fileExists(atPath: manifestURL.path),
               try FileManager.default.contentsOfDirectory(atPath: folder.path).isEmpty {
                // Termination before creating the manifest cannot have reached a Contacts write.
                try FileManager.default.removeItem(at: folder)
                return nil
            }
            let manifest = try JSONDecoder().decode(VersionManifest.self, from: Data(contentsOf: manifestURL))
            guard manifest.schema == 1, folder.lastPathComponent == manifest.version.id.uuidString else { throw ContactVersionError.historyUnavailable }
            return manifest
        }
    }

    private func writes(in folder: URL) throws -> [VersionWrite] {
        try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            .filter { $0.lastPathComponent != "manifest.json" }
            .map { try JSONDecoder().decode(VersionWrite.self, from: Data(contentsOf: $0)) }
    }

    private func finalize(folder: URL, status: ContactVersionStatus) throws {
        let url = folder.appendingPathComponent("manifest.json")
        let manifest = try JSONDecoder().decode(VersionManifest.self, from: Data(contentsOf: url))
        var changes: [ContactVersionChange] = []
        // Enumeration may resolve /var to /private/var. URL equality cannot identify this file.
        for file in try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) where file.lastPathComponent != "manifest.json" {
            let write = try JSONDecoder().decode(VersionWrite.self, from: Data(contentsOf: file))
            let resolved = try ContactVersionSession.resolve(write, source: source)
            if !write.confirmed { try writeHistory(resolved, to: file) }
            changes += resolved.changes
        }
        guard !changes.isEmpty else { try FileManager.default.removeItem(at: folder); return }
        let old = manifest.version
        let version = ContactVersion(id: old.id, ordinal: old.ordinal, createdAt: old.createdAt, kind: old.kind,
                                     targetOrdinal: old.targetOrdinal, status: status, contactCount: Set(changes.map(\.contactID)).count, fieldCount: changes.count)
        try writeHistory(VersionManifest(schema: 1, version: version), to: url)
    }
}
