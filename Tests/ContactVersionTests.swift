@testable import Phonetic
import Contacts
import Foundation
import os
import Testing

/// Mutable Contacts objects never escape the lock; reads return independent immutable copies.
private final class VersionSource: ContactVersionSource {
    struct State {
        var contacts: [String: CNMutableContact] = [:]
        var writes = 0
        var reads = 0
        var nicknameOnSecondRead: String?
        var allowed = true
        var failBeforeSave = false
        var failAfterSave = false
        var beforeSave: (@Sendable () throws -> Void)?
    }
    let state = OSAllocatedUnfairLock(uncheckedState: State())
    func hasAccess() -> Bool { state.withLockUnchecked { $0.allowed } }
    func read(identifier: String, fields: [ContactVersionField]) throws -> CNContact? {
        try state.withLockUnchecked {
            guard $0.allowed else { throw ContactVersionError.accessNeeded }
            $0.reads += 1
            if $0.reads == 2, let nickname = $0.nicknameOnSecondRead {
                $0.contacts[identifier]?.nickname = nickname
            }
            return $0.contacts[identifier]?.copy() as? CNContact
        }
    }
    func save(_ contact: CNMutableContact) throws {
        try state.withLockUnchecked {
            try $0.beforeSave?()
            if $0.failBeforeSave { throw ContactVersionError.saveFailed }
            $0.contacts[contact.identifier] = contact.mutableCopy() as? CNMutableContact
            $0.writes += 1
            if $0.failAfterSave { throw ContactVersionError.saveFailed }
        }
    }
    func put(_ contact: CNContact) { state.withLockUnchecked { $0.contacts[contact.identifier] = contact.mutableCopy() as? CNMutableContact } }
    func nickname(_ id: String) -> String? { state.withLockUnchecked { $0.contacts[id]?.nickname } }
    var writes: Int { state.withLockUnchecked { $0.writes } }
}

private struct VersionFixture {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("ContactVersionsTests-\(UUID().uuidString)")
    let source = VersionSource()
    var store: ContactVersionStore { ContactVersionStore(root: root, source: source) }
    func cleanup() { try? FileManager.default.removeItem(at: root) }
    func contact(_ nickname: String = "original") -> CNMutableContact {
        let contact = CNMutableContact()
        contact.givenName = "Ada"
        contact.nickname = nickname
        source.put(contact)
        return contact
    }
    func change(_ contact: CNContact, to value: String, session: ContactVersionSession) throws {
        let mutable = contact.mutableCopy() as! CNMutableContact
        mutable.nickname = value
        try session.save(original: contact, modified: mutable)
    }

    func makeVersions(_ names: [String], store: ContactVersionStore) async throws -> String {
        let contact = contact()
        for name in names {
            let before = try #require(try source.read(identifier: contact.identifier, fields: [.nickname]))
            let session = try await store.begin(kind: .editContact)
            try change(before, to: name, session: session)
            try await store.finish(session, outcome: .completed)
        }
        return contact.identifier
    }
}

struct ContactVersionTests {
    @Test("Storage limits reject oversized changes before touching Contacts")
    static func oversizedHistory() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = ContactVersionStore(root: f.root, source: f.source, byteLimit: 100_000)
        let contact = f.contact()
        let session = try await store.begin(kind: .editContact)
        #expect(throws: ContactVersionError.storageLimitReached) {
            try f.change(contact, to: String(repeating: "x", count: 200_000), session: session)
        }
        #expect(f.source.writes == 0 && f.source.nickname(contact.identifier) == "original")
        try await store.finish(session, outcome: .failed(.storageLimitReached))
        #expect(try await store.versions().isEmpty)
    }

    @Test("A batch reaching its history limit retains every successful write in a partial version")
    static func partialHistoryLimit() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let limit: Int64 = 65_536
        let store = ContactVersionStore(root: f.root, source: f.source, byteLimit: limit)
        let session = try await store.begin(kind: .addPinyin)
        var changed: [String] = []
        var reachedLimit = false
        for _ in 0 ..< 30 {
            let contact = f.contact()
            do {
                try f.change(contact, to: String(repeating: "x", count: 2048), session: session)
                changed.append(contact.identifier)
            } catch ContactVersionError.storageLimitReached {
                reachedLimit = true
                #expect(f.source.nickname(contact.identifier) == "original")
                break
            }
        }
        #expect(reachedLimit && !changed.isEmpty && f.source.writes == changed.count)
        try await store.finish(session, outcome: .failed(.storageLimitReached))
        let history = try await store.overview()
        #expect(history.usedBytes <= limit)
        #expect(history.versions.first?.status == .failed && history.versions.first?.contactCount == changed.count)
        #expect(try await store.preview(targetOrdinal: 0).entries.count == changed.count)
    }

    @Test("Over-limit history is automatically trimmed and remains readable")
    static func existingHistoryLimit() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store
        let names = ["one", "two", "three", "four"].map { String(repeating: $0, count: 5000) }
        let identifier = try await f.makeVersions(names, store: store)
        let used = try await store.overview().usedBytes
        let limited = ContactVersionStore(root: f.root, source: f.source, byteLimit: used * 3 / 4)
        let history = try await limited.overview()
        #expect(history.usedBytes <= history.limitBytes && history.earliestOrdinal > 0)
        #expect(!history.versions.isEmpty && history.versions.count < names.count)
        #expect(f.source.nickname(identifier) == names.last && f.source.writes == names.count)
        let next = try await limited.begin(kind: .editContact)
        try await limited.finish(next, outcome: .completed)
    }

    @Test("Automatic prefix removal preserves restores and rejects targets below the new boundary")
    static func prefixCleanup() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store
        let names = ["one", "two", "three", "four"].map { String(repeating: $0, count: 5000) }
        let identifier = try await f.makeVersions(names, store: store)
        let before = try await store.overview()
        let outdated = try await store.preview(targetOrdinal: 0)
        let limited = ContactVersionStore(root: f.root, source: f.source, byteLimit: before.usedBytes * 3 / 4)
        let cleaned = try await limited.overview()
        #expect(cleaned.earliestOrdinal > 0 && cleaned.earliestOrdinal < 4)
        #expect(cleaned.usedBytes < before.usedBytes && f.source.writes == 4)
        await #expect(throws: ContactVersionError.historyChanged) { try await limited.preview(targetOrdinal: 0) }
        await #expect(throws: ContactVersionError.historyChanged) {
            try await limited.begin(kind: .restore, targetOrdinal: outdated.targetOrdinal, expectedHead: outdated.headID, checkHead: true)
        }
        let preview = try await limited.preview(targetOrdinal: cleaned.earliestOrdinal)
        let expected = names[cleaned.earliestOrdinal - 1]
        #expect(preview.entries.first?.change.before.text == expected)
        let restore = try await limited.begin(kind: .restore, targetOrdinal: preview.targetOrdinal, expectedHead: preview.headID, checkHead: true)
        _ = try await limited.restore(preview, selected: Set(preview.entries.map(\.id)), session: restore, shouldStop: { false }, progress: { _, _ in })
        try await limited.finish(restore, outcome: .completed)
        #expect(f.source.nickname(identifier) == expected)
        #expect(try await limited.versions().first?.ordinal == 5)
    }

    @Test("Removing an oversized completed version advances the baseline without reusing version numbers")
    static func clearAllHistory() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store
        let largeName = String(repeating: "x", count: 100_000)
        let identifier = try await f.makeVersions([largeName], store: store)
        let limited = ContactVersionStore(root: f.root, source: f.source, byteLimit: 100_000)
        let cleaned = try await limited.overview()
        #expect(cleaned.versions.isEmpty && cleaned.earliestOrdinal == 1 && cleaned.usedBytes < cleaned.limitBytes)
        #expect(f.source.writes == 1 && f.source.nickname(identifier) == largeName)
        #expect(try await limited.preview(targetOrdinal: 1).entries.isEmpty)
        let contact = f.contact()
        let next = try await limited.begin(kind: .editContact)
        try f.change(contact, to: "new", session: next)
        try await limited.finish(next, outcome: .completed)
        #expect(try await limited.versions().first?.ordinal == 2)
        #expect(try await limited.preview(targetOrdinal: 1).entries.first?.change.before.text == "original")
        await #expect(throws: ContactVersionError.historyChanged) { try await limited.preview(targetOrdinal: 0) }
    }

    @Test("A running batch reclaims completed versions without deleting its own pending journal")
    static func automaticCleanupDuringBatch() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store
        _ = try await f.makeVersions([String(repeating: "a", count: 10_000), String(repeating: "b", count: 10_000)], store: store)
        let before = try await store.overview()
        let limited = ContactVersionStore(root: f.root, source: f.source, byteLimit: before.usedBytes + 80_000)
        let session = try await limited.begin(kind: .addPinyin)
        var identifiers: Set<String> = []
        for _ in 0 ..< 5 {
            let contact = f.contact()
            try f.change(contact, to: String(repeating: "x", count: 6000), session: session)
            identifiers.insert(contact.identifier)
        }
        try await limited.finish(session, outcome: .completed)
        let after = try await limited.overview()
        #expect(after.earliestOrdinal > 0 && after.usedBytes <= after.limitBytes)
        #expect(after.versions.first?.ordinal == 3 && after.versions.first?.contactCount == 5)
        let preview = try await limited.preview(targetOrdinal: after.earliestOrdinal)
        #expect(identifiers.isSubset(of: Set(preview.entries.map { $0.change.contactID })))
        #expect(f.source.writes == 7)
    }

    @Test("An impossible single change does not discard older usable versions")
    static func oversizedChangeKeepsHistory() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store
        _ = try await f.makeVersions(["one"], store: store)
        let originalID = try await store.versions().first?.id
        let used = try await store.overview().usedBytes
        let limited = ContactVersionStore(root: f.root, source: f.source, byteLimit: used + 1)
        let contact = f.contact()
        let session = try await limited.begin(kind: .editContact)
        #expect(throws: ContactVersionError.storageLimitReached) {
            try f.change(contact, to: String(repeating: "x", count: 200_000), session: session)
        }
        try await limited.finish(session, outcome: .failed(.storageLimitReached))
        #expect(try await limited.versions().map(\.id) == [originalID].compactMap { $0 })
        #expect(try await limited.overview().earliestOrdinal == 0)
        #expect(f.source.writes == 1)
    }

    @Test("A contact edited during automatic reclamation is revalidated before any save")
    static func externalChangeDuringReclamation() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store
        _ = try await f.makeVersions([String(repeating: "x", count: 30_000)], store: store)
        let used = try await store.overview().usedBytes
        let limited = ContactVersionStore(root: f.root, source: f.source, byteLimit: used + 50_000)
        let contact = f.contact()
        let session = try await limited.begin(kind: .editContact)
        f.source.state.withLockUnchecked { $0.reads = 0; $0.nicknameOnSecondRead = "manual" }
        #expect(throws: ContactVersionError.contactsChanged) {
            try f.change(contact, to: String(repeating: "y", count: 10_000), session: session)
        }
        try await limited.finish(session, outcome: .failed(.contactsChanged))
        #expect(f.source.nickname(contact.identifier) == "manual" && f.source.writes == 1)
    }

    @Test("A validated restore remains usable when retention removes its original target during processing")
    static func restoreSurvivesAutomaticCleanup() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store
        let names = (1 ... 80).map { String($0) }
        let identifier = try await f.makeVersions(names, store: store)
        let preview = try await store.preview(targetOrdinal: 0)
        let limited = ContactVersionStore(root: f.root, source: f.source, byteLimit: 65_536)
        let session = try await limited.begin(kind: .restore, targetOrdinal: 0, expectedHead: preview.headID, checkHead: true)
        _ = try await limited.restore(preview, selected: Set(preview.entries.map(\.id)), session: session, shouldStop: { false }, progress: { _, _ in })
        try await limited.finish(session, outcome: .completed)
        let after = try await limited.overview()
        #expect(after.earliestOrdinal > preview.targetOrdinal && after.usedBytes <= after.limitBytes)
        #expect(after.versions.first?.ordinal == 81 && f.source.nickname(identifier) == "original")
        let undo = try await limited.preview(targetOrdinal: after.earliestOrdinal)
        #expect(undo.entries.first?.change.before.text == String(after.earliestOrdinal))
    }

    @Test("A no-op at capacity does not evict retained versions to create temporary job metadata")
    static func noOpPreservesFullHistory() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store
        _ = try await f.makeVersions(["one"], store: store)
        let before = try await store.overview()
        let limited = ContactVersionStore(root: f.root, source: f.source, byteLimit: before.usedBytes)
        let session = try await limited.begin(kind: .editContact)
        try await limited.finish(session, outcome: .completed)
        let after = try await limited.overview()
        #expect(after.versions.map(\.id) == before.versions.map(\.id) && after.earliestOrdinal == 0)
        #expect(f.source.writes == 1)
    }

    @Test("Interrupted deletion resumes from its durable boundary and ignores partially deleted trash")
    static func interruptedCleanup() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store
        _ = try await f.makeVersions(["one", "two", "three"], store: store)
        let before = try await store.versions()
        try JSONSerialization.data(withJSONObject: ["schema": 1, "earliestOrdinal": 2])
            .write(to: f.root.appendingPathComponent(".boundary.json"), options: .atomic)
        let trash = f.root.appendingPathComponent(".discarded/partial", isDirectory: true)
        try FileManager.default.createDirectory(at: trash, withIntermediateDirectories: true)
        try Data("partial".utf8).write(to: trash.appendingPathComponent("manifest.json"))
        let reopened = f.store
        let recovered = try await reopened.overview()
        #expect(recovered.earliestOrdinal == 2 && recovered.versions.map(\.ordinal) == [3])
        #expect(!FileManager.default.fileExists(atPath: f.root.appendingPathComponent(".discarded").path))
        for version in before where version.ordinal <= 2 {
            #expect(!FileManager.default.fileExists(atPath: f.root.appendingPathComponent(version.id.uuidString).path))
        }
        #expect(try await reopened.preview(targetOrdinal: 2).entries.first?.change.before.text == "two")
        #expect(f.source.writes == 3)
    }

    @Test("Idle maintenance refuses an active job and restore authorization cannot be reused for another preview")
    static func cleanupGuards() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store
        _ = try await f.makeVersions(["one"], store: store)
        let preview = try await store.preview(targetOrdinal: 0)
        let active = try await store.begin(kind: .restore, targetOrdinal: 0, expectedHead: preview.headID, checkHead: true)
        await #expect(throws: ContactVersionError.busy) { try await store.overview() }
        let wrong = ContactRestorePreview(headID: UUID(), targetOrdinal: 0, entries: preview.entries)
        await #expect(throws: ContactVersionError.historyChanged) {
            try await store.restore(wrong, selected: Set(wrong.entries.map(\.id)), session: active, shouldStop: { false }, progress: { _, _ in })
        }
        try await store.finish(active, outcome: .failed(.historyChanged))
        #expect(try await store.overview().earliestOrdinal == 0)
        #expect(try await store.versions().count == 1 && f.source.writes == 1)
    }

    @Test("History names use native name order and retain personal-name components")
    static func formattedContactNames() throws {
        let contact = CNMutableContact()
        contact.familyName = "陈"
        contact.givenName = "业斌"
        contact.nickname = "original"
        let modified = contact.mutableCopy() as! CNMutableContact
        modified.nickname = "CYB"
        let chineseEdit = try ContactVersionSession.edit(original: contact, modified: modified)
        let name = try #require(chineseEdit.changes.first?.contactName)
        #expect(name.replacingOccurrences(of: " ", with: "") == "陈业斌")

        contact.namePrefix = "Dr."
        contact.givenName = "Ada"
        contact.middleName = "M."
        contact.familyName = "Lovelace"
        contact.organizationName = "Fallback Company"
        let englishModified = contact.mutableCopy() as! CNMutableContact
        englishModified.nickname = "search initials"
        let englishEdit = try ContactVersionSession.edit(original: contact, modified: englishModified)
        let fullName = try #require(englishEdit.changes.first?.contactName)
        #expect(["Dr.", "Ada", "M.", "Lovelace"].allSatisfy { fullName.contains($0) })
        #expect(!fullName.contains("Fallback Company") && !fullName.contains("original"))
    }

    @Test("Previews correct legacy name labels without rewriting the journal or changing restore values")
    static func legacyPreviewNames() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store, contact = f.contact()
        contact.familyName = "陈"
        contact.givenName = "业斌"
        f.source.put(contact)
        let modified = contact.mutableCopy() as! CNMutableContact
        modified.nickname = "CYB"
        let change = ContactVersionChange(contactID: contact.identifier, contactName: "业斌 陈", field: .nickname,
                                          before: try ContactVersionValue.read(.nickname, from: contact), after: try ContactVersionValue.read(.nickname, from: modified))
        let session = try await store.begin(kind: .editContact)
        try session.save([change])
        try await store.finish(session, outcome: .completed)

        let preview = try await store.preview(targetOrdinal: 0)
        let entry = try #require(preview.entries.first)
        #expect(entry.change.contactName.replacingOccurrences(of: " ", with: "") == "陈业斌")
        #expect(entry.change.before.text == "original" && entry.change.after.text == "CYB")
        #expect(f.source.writes == 1)

        _ = f.source.state.withLockUnchecked { $0.contacts.removeValue(forKey: contact.identifier) }
        let unavailable = try await store.preview(targetOrdinal: 0)
        #expect(unavailable.entries.first?.change.contactName == "业斌 陈")
        #expect(unavailable.entries.first?.current == nil)
    }

    @Test("History finalizes and recovers through an aliased container path", arguments: [true, false])
    static func aliasedHistoryDirectory(aliasIsRoot: Bool) async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let actual = f.root.appendingPathComponent("History Data", isDirectory: true)
        let alias = f.root.appendingPathComponent("History Alias", isDirectory: true)
        try FileManager.default.createDirectory(at: actual, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: actual)
        let historyRoot = aliasIsRoot ? alias : alias.appendingPathComponent("ContactVersions", isDirectory: true)
        let store = ContactVersionStore(root: historyRoot, source: f.source)
        let contact = f.contact()
        let session = try await store.begin(kind: .editContact)
        try f.change(contact, to: "changed", session: session)
        // Enumeration can return a resolved path rather than the URL used to create the file.
        try await store.finish(session, outcome: .completed)
        #expect(try await store.versions().count == 1)
        #expect(try await store.preview(targetOrdinal: 0).entries.first?.change.before.text == "original")

        let pending = try await store.begin(kind: .editContact)
        let current = try #require(try f.source.read(identifier: contact.identifier, fields: [.nickname]))
        try f.change(current, to: "pending", session: pending)
        let reopened = ContactVersionStore(root: historyRoot, source: f.source)
        let recovered = try await reopened.versions()
        #expect(recovered.count == 2 && recovered.first?.status == .interrupted)
        #expect(try await reopened.preview(targetOrdinal: 0).entries.first?.change.before.text == "original")
    }

    @Test("No-op edits and failed writes without changes do not create versions")
    static func noOpAndFailedSave() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store, contact = f.contact()
        let first = try await store.begin(kind: .editContact)
        try f.change(contact, to: "original", session: first)
        try await store.finish(first, outcome: .completed)
        #expect(try await store.versions().isEmpty)
        #expect(f.source.writes == 0)
        f.source.state.withLockUnchecked { $0.failBeforeSave = true }
        let second = try await store.begin(kind: .editContact)
        #expect(throws: ContactVersionError.saveFailed) { try f.change(contact, to: "edited", session: second) }
        try await store.finish(second, outcome: .failed(.saveFailed))
        #expect(try await store.versions().isEmpty)
        #expect(f.source.nickname(contact.identifier) == "original")
    }

    @Test("Intent is durable before Contacts saves and history records only changed fields")
    static func durableIntent() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store, contact = f.contact()
        let session = try await store.begin(kind: .editContact)
        let folder = f.root.appendingPathComponent(session.id.uuidString)
        f.source.state.withLockUnchecked { $0.beforeSave = {
            let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            let event = try #require(files.first { $0.lastPathComponent != "manifest.json" })
            let json = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: event)) as? [String: Any])
            #expect(json["confirmed"] as? Bool == false)
            let changes = try #require(json["changes"] as? [[String: Any]])
            #expect(changes.count == 1 && changes.first?["field"] as? String == "nickname")
        } }
        try f.change(contact, to: "changed", session: session)
        try await store.finish(session, outcome: .completed)
        let versions = try await store.versions()
        #expect(versions.count == 1 && versions[0].ordinal == 1 && versions[0].fieldCount == 1)
        #expect(try f.root.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true)
        #expect(throws: ContactVersionError.busy) { try f.change(contact, to: "late", session: session) }
    }

    @Test("History persistence failure prevents a contact write")
    static func diskFailure() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store, contact = f.contact()
        let session = try await store.begin(kind: .editContact)
        try FileManager.default.removeItem(at: f.root.appendingPathComponent(session.id.uuidString))
        #expect(throws: ContactVersionError.historyUnavailable) { try f.change(contact, to: "changed", session: session) }
        #expect(f.source.writes == 0)
    }

    @Test("An interrupted save is recovered and successful partial writes remain undoable")
    static func interruptedRecovery() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let contact = f.contact()
        let store = f.store
        let session = try await store.begin(kind: .addPinyin)
        f.source.state.withLockUnchecked { $0.failAfterSave = true }
        #expect(throws: ContactVersionError.saveFailed) { try f.change(contact, to: "changed", session: session) }
        // Reopening simulates termination between the Contacts write and journal confirmation.
        let reopened = f.store
        let versions = try await reopened.versions()
        #expect(versions.count == 1 && versions[0].status == .interrupted)
        let preview = try await reopened.preview(targetOrdinal: 0)
        #expect(preview.entries.count == 1 && !preview.entries[0].isConflict)
        #expect(preview.entries[0].change.before.text == "original")
    }

    @Test("Cancellation retains changes and concurrent operations are rejected")
    static func partialCancellation() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store, contact = f.contact()
        let session = try await store.begin(kind: .clearFields)
        await #expect(throws: ContactVersionError.busy) { try await store.begin(kind: .addPinyin) }
        try f.change(contact, to: "", session: session)
        try await store.finish(session, outcome: .stopped)
        #expect(try await store.versions().first?.status == .stopped)
        #expect(try await store.preview(targetOrdinal: 0).entries.first?.change.before.text == "original")
    }

    @Test("Restoring any earlier version appends a reversible version without deleting history")
    static func versionFolding() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store, contact = f.contact()
        for name in ["one", "two", "three"] {
            let before = try #require(try f.source.read(identifier: contact.identifier, fields: [.nickname]))
            let session = try await store.begin(kind: .editContact)
            try f.change(before, to: name, session: session)
            try await store.finish(session, outcome: .completed)
        }
        let preview = try await store.preview(targetOrdinal: 1)
        #expect(preview.entries.count == 1 && preview.entries[0].change.before.text == "one")
        #expect(preview.entries[0].current?.text == "three")
        let restore = try await store.begin(kind: .restore, targetOrdinal: 1, expectedHead: preview.headID, checkHead: true)
        #expect(try await store.restore(preview, selected: Set(preview.entries.map(\.id)), session: restore, shouldStop: { false }, progress: { _, _ in }) == 0)
        try await store.finish(restore, outcome: .completed)
        #expect(f.source.nickname(contact.identifier) == "one")
        let versions = try await store.versions()
        #expect(versions.count == 4 && versions.first?.targetOrdinal == 1)
        let forwardAgain = try await store.preview(targetOrdinal: 3)
        #expect(forwardAgain.entries.first?.change.before.text == "three" && forwardAgain.entries.first?.isConflict == false)
        let baseline = try await store.preview(targetOrdinal: 0)
        #expect(baseline.entries.first?.change.before.text == "original" && baseline.entries.first?.isConflict == false)
    }

    @Test("External changes and unavailable contacts are not safe restore defaults")
    static func conflictsAndMissingContacts() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store, contact = f.contact(), deleted = f.contact()
        let session = try await store.begin(kind: .addPinyin)
        try f.change(contact, to: "generated", session: session)
        try f.change(deleted, to: "generated", session: session)
        try await store.finish(session, outcome: .completed)
        let external = contact.mutableCopy() as! CNMutableContact
        external.nickname = "manual"
        f.source.put(external)
        _ = f.source.state.withLockUnchecked { $0.contacts.removeValue(forKey: deleted.identifier) }
        let preview = try await store.preview(targetOrdinal: 0)
        #expect(preview.entries.count == 2 && preview.entries.allSatisfy(\.isConflict))
        #expect(preview.entries.contains { $0.current == nil })
        // An explicit conflict selection is restorable, while deleted contacts are never recreated.
        let restore = try await store.begin(kind: .restore, targetOrdinal: 0, expectedHead: preview.headID, checkHead: true)
        _ = try await store.restore(preview, selected: Set(preview.entries.map(\.id)), session: restore, shouldStop: { false }, progress: { _, _ in })
        try await store.finish(restore, outcome: .completed)
        #expect(f.source.nickname(contact.identifier) == "original")
        #expect(f.source.nickname(deleted.identifier) == nil)
        let undoRestore = try await store.preview(targetOrdinal: 1)
        #expect(undoRestore.entries.first?.change.before.text == "manual")
    }

    @Test("Changes after preview are skipped and stale history heads cannot be applied")
    static func previewRevalidation() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store, contact = f.contact()
        let session = try await store.begin(kind: .editContact)
        try f.change(contact, to: "generated", session: session)
        try await store.finish(session, outcome: .completed)
        let preview = try await store.preview(targetOrdinal: 0)
        let external = contact.mutableCopy() as! CNMutableContact
        external.nickname = "newer"
        f.source.put(external)
        let restore = try await store.begin(kind: .restore, targetOrdinal: preview.targetOrdinal, expectedHead: preview.headID, checkHead: true)
        let skipped = try await store.restore(preview, selected: Set(preview.entries.map(\.id)), session: restore, shouldStop: { false }, progress: { _, _ in })
        try await store.finish(restore, outcome: .completed)
        #expect(skipped == 1 && f.source.nickname(contact.identifier) == "newer")
        #expect(try await store.versions().count == 1)
        let next = try await store.begin(kind: .editContact)
        try f.change(external, to: "another", session: next)
        try await store.finish(next, outcome: .completed)
        await #expect(throws: ContactVersionError.historyChanged) {
            try await store.begin(kind: .restore, targetOrdinal: preview.targetOrdinal, expectedHead: preview.headID, checkHead: true)
        }
        let discontinuous = try await store.preview(targetOrdinal: 0)
        #expect(discontinuous.entries.first?.isConflict == true)
    }

    @Test("Edits refuse changed source names and changes already matching the target need no write")
    static func liveValidation() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store, contact = f.contact()
        let external = contact.mutableCopy() as! CNMutableContact
        external.givenName = "New Name"
        f.source.put(external)
        let session = try await store.begin(kind: .editContact)
        #expect(throws: ContactVersionError.contactsChanged) { try f.change(contact, to: "generated", session: session) }
        #expect(f.source.writes == 0)
        try f.change(external, to: "generated", session: session)
        try await store.finish(session, outcome: .completed)
        external.nickname = "original"
        f.source.put(external)
        #expect(try await store.preview(targetOrdinal: 0).entries.isEmpty)
    }

    @Test("Multivalue archives retain labels and identifiers without retaining unrelated fields")
    static func arrayRoundTrip() throws {
        let contact = CNMutableContact()
        contact.givenName = "private name"
        contact.note = "private note"
        contact.socialProfiles = [CNLabeledValue(label: CNLabelHome,
                                                 value: CNSocialProfile(urlString: "https://example.com/ada", username: "ada", userIdentifier: "123", service: "example"))]
        contact.instantMessageAddresses = [CNLabeledValue(label: CNLabelWork,
                                                          value: CNInstantMessageAddress(username: "ada", service: "example"))]
        for field in [ContactVersionField.socialProfiles, .instantMessageAddresses] {
            let before = try ContactVersionValue.read(field, from: contact)
            let restored = CNMutableContact()
            try before.apply(field, to: restored)
            #expect(try ContactVersionValue.read(field, from: restored) == before)
            #expect(restored.givenName.isEmpty && restored.note.isEmpty)
        }
    }

    @Test("Denied access and corrupt journals fail closed")
    static func inaccessibleHistory() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store
        f.source.state.withLockUnchecked { $0.allowed = false }
        await #expect(throws: ContactVersionError.accessNeeded) { try await store.begin(kind: .editContact) }
        f.source.state.withLockUnchecked { $0.allowed = true }
        let session = try await store.begin(kind: .editContact)
        let manifest = f.root.appendingPathComponent(session.id.uuidString).appendingPathComponent("manifest.json")
        try Data("corrupt".utf8).write(to: manifest)
        let reopened = f.store
        await #expect(throws: ContactVersionError.historyUnavailable) { try await reopened.versions() }
        #expect(f.source.writes == 0)
    }

    @Test("Unresolved interrupted writes require access and ambiguous values stay conflicted")
    static func ambiguousRecovery() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store, contact = f.contact()
        let session = try await store.begin(kind: .addPinyin)
        f.source.state.withLockUnchecked { $0.failAfterSave = true }
        #expect(throws: ContactVersionError.saveFailed) { try f.change(contact, to: "generated", session: session) }
        let external = contact.mutableCopy() as! CNMutableContact
        external.nickname = "manual"
        f.source.put(external)
        f.source.state.withLockUnchecked { $0.allowed = false }
        let reopened = f.store
        await #expect(throws: ContactVersionError.accessNeeded) { try await reopened.versions() }
        await #expect(throws: ContactVersionError.accessNeeded) { try await reopened.begin(kind: .editContact) }
        f.source.state.withLockUnchecked { $0.allowed = true }
        let preview = try await reopened.preview(targetOrdinal: 0)
        #expect(preview.entries.count == 1 && preview.entries[0].isConflict)
        #expect(preview.entries[0].current?.text == "manual")
    }

    @Test("Journal event order folds repeated writes and a stopped restore adds no empty version")
    static func repeatedWritesAndStoppedRestore() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store, contact = f.contact()
        let session = try await store.begin(kind: .editContact)
        try f.change(contact, to: "first", session: session)
        let first = try #require(try f.source.read(identifier: contact.identifier, fields: [.nickname]))
        try f.change(first, to: "second", session: session)
        try await store.finish(session, outcome: .completed)
        let preview = try await store.preview(targetOrdinal: 0)
        #expect(preview.entries.count == 1 && preview.entries[0].change.before.text == "original")
        #expect(preview.entries[0].current?.text == "second" && !preview.entries[0].isConflict)
        let stopped = try await store.begin(kind: .restore, targetOrdinal: 0, expectedHead: preview.headID, checkHead: true)
        _ = try await store.restore(preview, selected: Set(preview.entries.map(\.id)), session: stopped, shouldStop: { true }, progress: { _, _ in })
        try await store.finish(stopped, outcome: .stopped)
        #expect(try await store.versions().count == 1)
        #expect(f.source.nickname(contact.identifier) == "second")
    }

    @Test("Manual editor saves record every changed field and keep unrelated values")
    static func manualEditorSave() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store, contact = f.contact()
        let modified = contact.mutableCopy() as! CNMutableContact
        modified.nickname = "edited"
        modified.phoneticGivenName = "Ada"
        let edit = try ContactVersionSession.edit(original: contact, modified: modified)
        let session = try await store.begin(kind: .editContact)
        try await store.saveEdit(edit, session: session)
        try await store.finish(session, outcome: .completed)
        let version = try #require(try await store.versions().first)
        #expect(version.kind == .editContact && version.fieldCount == 2)
        let preview = try await store.preview(targetOrdinal: 0)
        #expect(Set(preview.entries.map { $0.change.field }) == [.nickname, .phoneticGivenName])
        #expect(preview.entries.allSatisfy { !$0.isConflict })
        #expect(f.source.nickname(contact.identifier) == "edited")
        let saved = try #require(try f.source.read(identifier: contact.identifier, fields: [.givenName]))
        #expect(saved.givenName == "Ada")
    }

    @Test("Manual editor rejects stale snapshots even when another field changed")
    static func staleManualEditorSave() async throws {
        let f = VersionFixture(); defer { f.cleanup() }
        let store = f.store, contact = f.contact()
        let modified = contact.mutableCopy() as! CNMutableContact
        modified.nickname = "edited"
        let edit = try ContactVersionSession.edit(original: contact, modified: modified)
        let external = contact.mutableCopy() as! CNMutableContact
        external.jobTitle = "External edit"
        f.source.put(external)
        let session = try await store.begin(kind: .editContact)
        await #expect(throws: ContactVersionError.contactsChanged) { try await store.saveEdit(edit, session: session) }
        try await store.finish(session, outcome: .failed(.contactsChanged))
        #expect(f.source.writes == 0 && f.source.nickname(contact.identifier) == "original")
        #expect(try await store.versions().isEmpty)
    }

    @Test("Manual editor rejects foreign and closed operation sessions")
    static func manualEditorSessionOwnership() async throws {
        let f = VersionFixture(), other = VersionFixture()
        defer { f.cleanup(); other.cleanup() }
        let store = f.store, otherStore = other.store, contact = f.contact()
        let modified = contact.mutableCopy() as! CNMutableContact
        modified.nickname = "edited"
        let edit = try ContactVersionSession.edit(original: contact, modified: modified)
        let session = try await store.begin(kind: .editContact)
        let foreign = try await otherStore.begin(kind: .editContact)
        await #expect(throws: ContactVersionError.busy) { try await store.saveEdit(edit, session: foreign) }
        try await store.finish(session, outcome: .stopped)
        await #expect(throws: ContactVersionError.busy) { try await store.saveEdit(edit, session: session) }
        try await otherStore.finish(foreign, outcome: .stopped)
        #expect(f.source.writes == 0)
        #expect(try await store.versions().isEmpty)
    }
}
