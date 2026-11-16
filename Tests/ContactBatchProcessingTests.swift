@testable import Phonetic
import Contacts
import Foundation
import os
import Testing
import UIKit

private let lowTimeWarning = String(localized: "Background time is running low. Open Phonetic to continue processing.")
private let completionNotice = String(localized: "Your contacts have been updated.")

@MainActor
private final class BatchNotificationEnvironment {
    var state: UIApplication.State = .background
    var remainingTime: TimeInterval = 5
    var notifications: [String] = []
}

private final class BatchGate: @unchecked Sendable {
    // Synchronous Contacts callbacks wait on a worker thread; the test always opens the gate.
    private let condition = NSCondition()
    private var waiting = false
    private var opened = false

    var entered: Bool {
        condition.lock()
        defer { condition.unlock() }
        return waiting
    }

    func wait() {
        condition.lock()
        waiting = true
        while !opened {
            condition.wait()
        }
        condition.unlock()
    }

    func open() {
        condition.lock()
        opened = true
        condition.broadcast()
        condition.unlock()
    }
}

private final class BatchContactStore: CNContactStore, ContactVersionSource, @unchecked Sendable {
    struct State {
        var contacts: [CNContact]
        var writes = 0
        var enumerations = 0
        var allowed = true
    }

    // Mutable Contacts values never escape the lock; callers receive independent copies.
    private let state: OSAllocatedUnfairLock<State>
    let failWrite: Int?
    let failAfterWrite: Bool
    let failEnumeration: Bool
    let gate: BatchGate?
    let pauseAfterWrite: Bool
    let pauseWriteNumber: Int

    init(contacts: [CNContact], failWrite: Int? = nil, failAfterWrite: Bool = false,
         failEnumeration: Bool = false, gate: BatchGate? = nil, pauseAfterWrite: Bool = false, pauseWriteNumber: Int = 1) {
        state = OSAllocatedUnfairLock(uncheckedState: State(contacts: contacts.map { $0.copy() as! CNContact }))
        self.failWrite = failWrite
        self.failAfterWrite = failAfterWrite
        self.failEnumeration = failEnumeration
        self.gate = gate
        self.pauseAfterWrite = pauseAfterWrite
        self.pauseWriteNumber = pauseWriteNumber
        super.init()
    }

    var writes: Int {
        state.withLockUnchecked { $0.writes }
    }

    var enumerations: Int {
        state.withLockUnchecked { $0.enumerations }
    }

    var allowed: Bool {
        get { state.withLockUnchecked { $0.allowed } }
        set { state.withLockUnchecked { $0.allowed = newValue } }
    }

    func hasAccess() -> Bool {
        allowed
    }

    func read(identifier: String, fields: [ContactVersionField]) throws -> CNContact? {
        state.withLockUnchecked { $0.contacts.first { $0.identifier == identifier }?.copy() as? CNContact }
    }

    func save(_ contact: CNMutableContact) throws {
        let written = try state.withLockUnchecked { state in
            if state.writes + 1 == failWrite, !failAfterWrite {
                throw ContactVersionError.saveFailed
            }
            let index = try #require(state.contacts.firstIndex { $0.identifier == contact.identifier })
            state.contacts[index] = contact.copy() as! CNContact
            state.writes += 1
            return state.writes
        }
        if written == pauseWriteNumber, pauseAfterWrite {
            gate?.wait()
        }
        if written == failWrite, failAfterWrite {
            throw ContactVersionError.saveFailed
        }
    }

    override func enumerateContacts(with fetchRequest: CNContactFetchRequest, usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void) throws {
        let counting = fetchRequest.keysToFetch.count == 1
        let contacts = state.withLockUnchecked { state in
            state.enumerations += 1
            return state.contacts.map { $0.copy() as! CNContact }
        }
        if !counting, !pauseAfterWrite {
            gate?.wait()
        }
        for contact in contacts {
            var stop: ObjCBool = false
            block(contact, &stop)
            if stop.boolValue {
                break
            }
            if !counting, failEnumeration {
                throw ContactVersionError.saveFailed
            }
        }
    }
}

@MainActor
private final class BatchProcessingClient: ContinuedProcessingClient {
    var launch: (@MainActor (String) -> Void)?
    var attached = false
    var updates: [(checked: Int64, total: Int64)] = []
    var completions: [Bool] = []

    func prepare(onLaunch: @escaping @MainActor (String) -> Void, onExpiration: @escaping @MainActor (String) -> Void) -> Bool {
        launch = onLaunch
        return true
    }

    func submit(id: String, title: String, subtitle: String) async throws {
        launch?(id)
        attached = true
    }

    func update(id: String, checked: Int64, total: Int64, title: String, subtitle: String) {
        updates.append((checked, total))
    }

    func complete(id: String, success: Bool) {
        completions.append(success)
    }

    func cancelRequest(id: String) {}
}

@MainActor
private final class BatchFixture {
    let suite = "ContactBatchTests.\(UUID().uuidString)"
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("ContactBatchTests-\(UUID().uuidString)")
    let defaults: UserDefaults
    let source: BatchContactStore
    let history: ContactVersionStore
    let engine: PhoneticContacts

    init(contacts: [CNContact], failWrite: Int? = nil, failAfterWrite: Bool = false,
         failEnumeration: Bool = false, gate: BatchGate? = nil, pauseAfterWrite: Bool = false,
         processingTask: ContactProcessingTask? = nil, pauseWriteNumber: Int = 1,
         notificationEnvironment: BatchNotificationEnvironment? = nil) throws {
        defaults = try #require(UserDefaults(suiteName: suite))
        source = BatchContactStore(contacts: contacts, failWrite: failWrite, failAfterWrite: failAfterWrite,
                                   failEnumeration: failEnumeration, gate: gate, pauseAfterWrite: pauseAfterWrite, pauseWriteNumber: pauseWriteNumber)
        history = ContactVersionStore(root: root, source: source)
        engine = PhoneticContacts(userDefaults: defaults, contactStore: source, versionStore: history,
                                  processingTask: processingTask ?? ContactProcessingTask(client: nil),
                                  applicationState: { notificationEnvironment?.state ?? UIApplication.shared.applicationState },
                                  backgroundTimeRemaining: { notificationEnvironment?.remainingTime ?? UIApplication.shared.backgroundTimeRemaining },
                                  notificationHandler: { notificationEnvironment?.notifications.append($0) })
        defaults.set(false, forKey: kFixPolyphonicChar)
        defaults.set(false, forKey: kUseTones)
        defaults.set(false, forKey: kUpcasePinyin)
        defaults.set(true, forKey: kAlwaysSeparatePinyin)
        defaults.set(true, forKey: kPhoneticFirstAndLastName)
        defaults.set(true, forKey: kEnableNickname)
        defaults.set(false, forKey: kOverwriteAlreadyExists)
    }

    func cleanup() {
        source.gate?.open()
        defaults.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: root)
    }

    func run(clearing: Bool, resultHandler: @escaping PhoneticContacts.ResultHandler = { _, _ in }) async -> ContactOperationOutcome {
        if clearing {
            return await engine.cleanMandarinLatinPhonetic(resultHandler: resultHandler)
        }
        return await engine.execute(resultHandler: resultHandler)
    }
}

@MainActor
struct ContactBatchProcessingTests {
    private static func contact(family: String = "林", given: String = "沐晴") -> CNMutableContact {
        let contact = CNMutableContact()
        contact.familyName = family
        contact.givenName = given
        contact.phoneticFamilyName = "Original family"
        contact.phoneticGivenName = "Original given"
        return contact
    }

    @Test("Adding pinyin skips whitelist, Latin, and empty contacts, and records company conversion")
    static func addBatch() async throws {
        let person = contact(), latin = contact(family: "Lovelace", given: "Ada"), protected = contact()
        let company = CNMutableContact(), empty = CNMutableContact()
        company.organizationName = "林"
        let f = try BatchFixture(contacts: [person, latin, protected, company, empty])
        defer { f.cleanup() }
        f.defaults.set([protected.identifier], forKey: kWhitelistIdentifiersKey)
        f.defaults.set(true, forKey: kMassageCompanyKey)
        #expect(await f.run(clearing: false) == .completed)
        #expect(!f.engine.isProcessing && f.engine.contactsTotalCount == 5 && f.source.writes == 2)
        let saved = try #require(try f.source.read(identifier: person.identifier, fields: []))
        #expect(saved.phoneticFamilyName == "Lin" && saved.phoneticGivenName == "Mu Qing" && saved.nickname == "LMQ")
        let savedCompany = try #require(try f.source.read(identifier: company.identifier, fields: []))
        #expect(savedCompany.givenName == "林" && savedCompany.phoneticGivenName == "Lin" && savedCompany.nickname == "L")
        for contact in [latin, protected] {
            #expect(try f.source.read(identifier: contact.identifier, fields: [])?.phoneticGivenName == "Original given")
        }
        let version = try #require(try await f.history.versions().first)
        #expect(version.kind == .addPinyin && version.status == .completed && version.contactCount == 2)
        let preview = try await f.history.preview(targetOrdinal: 0)
        #expect(preview.entries.count == 6 && preview.entries.allSatisfy { !$0.isConflict })
        #expect(await f.run(clearing: false) == .completed)
        #expect(f.source.writes == 2)
        #expect(try await f.history.versions().count == 1)
    }

    @Test("Clearing preserves Latin phonetics, unselected fields, and all whitelist values")
    static func clearBatch() async throws {
        let person = contact(), latin = contact(family: "Lovelace", given: "Ada"), protected = contact()
        for contact in [person, latin, protected] {
            contact.nickname = "Keep nickname"; contact.note = "Clear note"
        }
        let f = try BatchFixture(contacts: [person, latin, protected])
        defer { f.cleanup() }
        f.defaults.set([protected.identifier], forKey: kWhitelistIdentifiersKey)
        f.defaults.set(true, forKey: kCleanNotesKey)
        #expect(await f.run(clearing: true) == .completed)
        let saved = try #require(try f.source.read(identifier: person.identifier, fields: []))
        #expect(saved.phoneticFamilyName.isEmpty && saved.phoneticGivenName.isEmpty && saved.note.isEmpty)
        #expect(saved.nickname == "Keep nickname" && saved.familyName == "林" && saved.givenName == "沐晴")
        let savedLatin = try #require(try f.source.read(identifier: latin.identifier, fields: []))
        #expect(savedLatin.phoneticGivenName == "Original given" && savedLatin.note.isEmpty)
        let savedProtected = try #require(try f.source.read(identifier: protected.identifier, fields: []))
        #expect(savedProtected.phoneticGivenName == "Original given" && savedProtected.note == "Clear note")
        let version = try #require(try await f.history.versions().first)
        #expect(version.kind == .clearFields && version.status == .completed && version.fieldCount == 4)
        #expect(f.source.writes == 2 && !f.engine.isProcessing)
    }

    @Test("A write failure stops the batch and retains every actual change in failed history",
          arguments: [false, true], [false, true])
    static func partialSaveFailure(clearing: Bool, afterWrite: Bool) async throws {
        let contacts = [contact(), contact(), contact()]
        let f = try BatchFixture(contacts: contacts, failWrite: 2, failAfterWrite: afterWrite)
        defer { f.cleanup() }
        #expect(await f.run(clearing: clearing) == .failed(.saveFailed))
        let changed = afterWrite ? 2 : 1
        #expect(f.source.writes == changed && !f.engine.isProcessing)
        let version = try #require(try await f.history.versions().first)
        #expect(version.status == .failed && version.contactCount == changed)
        let preview = try await f.history.preview(targetOrdinal: 0)
        #expect(Set(preview.entries.map { $0.change.contactID }) == Set(contacts.prefix(changed).map(\.identifier)))
        #expect(try f.source.read(identifier: contacts[2].identifier, fields: [])?.phoneticGivenName == "Original given")
    }

    @Test("An enumeration failure preserves partial history and releases the operation",
          arguments: [false, true])
    static func partialEnumerationFailure(clearing: Bool) async throws {
        let f = try BatchFixture(contacts: [contact(), contact()], failEnumeration: true)
        defer { f.cleanup() }
        #expect(await f.run(clearing: clearing) == .failed(.saveFailed))
        #expect(f.source.writes == 1 && !f.engine.isProcessing)
        let version = try #require(try await f.history.versions().first)
        #expect(version.status == .failed && version.contactCount == 1)
        let session = try await f.history.begin(kind: .editContact)
        try await f.history.finish(session, outcome: .stopped)
    }

    @Test("Empty batches complete without an empty version or a stuck processing flag", arguments: [false, true])
    static func emptyBatch(clearing: Bool) async throws {
        let f = try BatchFixture(contacts: [])
        defer { f.cleanup() }
        #expect(await f.run(clearing: clearing) == .completed)
        #expect(f.engine.contactsTotalCount == 0 && !f.engine.isProcessing && f.source.writes == 0)
        #expect(try await f.history.versions().isEmpty)
        #expect(await f.run(clearing: clearing) == .completed)
    }

    @Test("Rejected history sessions never enumerate or edit contacts", arguments: [false, true])
    static func rejectedSession(busy: Bool) async throws {
        let f = try BatchFixture(contacts: [contact()])
        defer { f.cleanup() }
        let session = busy ? try await f.history.begin(kind: .editContact) : nil
        f.source.allowed = busy
        #expect(await f.run(clearing: false) == .failed(busy ? .busy : .accessNeeded))
        #expect(f.source.enumerations == 0 && f.source.writes == 0 && !f.engine.isProcessing)
        if let session {
            try await f.history.finish(session, outcome: .stopped)
        }
    }

    @Test("Cancellation before launch closes history without writing contacts", arguments: [false, true])
    static func cancellationBeforeWork(clearing: Bool) async throws {
        let f = try BatchFixture(contacts: [contact()])
        defer { f.cleanup() }
        let run = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return await f.run(clearing: clearing)
        }
        #expect(await run.value == .stopped)
        #expect(f.source.enumerations == 0 && f.source.writes == 0 && !f.engine.isProcessing)
        #expect(try await f.history.versions().isEmpty)
        #expect(await f.run(clearing: clearing) == .completed)
    }

    @Test("Cancellation during a save waits for journaling and retains a stopped version", arguments: [false, true])
    static func cancellationDuringSave(clearing: Bool) async throws {
        let gate = BatchGate()
        let f = try BatchFixture(contacts: [contact(), contact()], gate: gate, pauseAfterWrite: true)
        defer { gate.open(); f.cleanup() }
        let run = Task { await f.run(clearing: clearing) }
        try await waitUntil { gate.entered }
        run.cancel()
        try await waitUntil { !f.engine.isProcessing }
        gate.open()
        #expect(await run.value == .stopped)
        #expect(f.source.writes == 1 && !f.engine.isProcessing)
        let version = try #require(try await f.history.versions().first)
        #expect(version.status == .stopped && version.contactCount == 1)
        #expect(try await f.history.preview(targetOrdinal: 0).entries.allSatisfy { !$0.isConflict })
        #expect(await f.run(clearing: clearing) == .completed)
        #expect(f.source.writes == 2)
    }

    @Test("Overlapping operations stay rejected while cancelled work is still unwinding")
    static func overlappingOperations() async throws {
        let gate = BatchGate()
        let f = try BatchFixture(contacts: [contact()], gate: gate)
        defer { gate.open(); f.cleanup() }
        let run = Task { await f.run(clearing: false) }
        try await waitUntil { gate.entered }
        #expect(await f.run(clearing: true) == .failed(.busy))
        f.engine.isProcessing = false
        #expect(await f.run(clearing: true) == .failed(.busy))
        gate.open()
        #expect(await run.value == .stopped)
        #expect(f.source.writes == 0 && !f.engine.isProcessing)
        #expect(try await f.history.versions().isEmpty)
        #expect(await f.run(clearing: false) == .completed)
        #expect(f.source.writes == 1)
    }

    @Test("Progress counts skipped contacts and drains before native task completion", arguments: [false, true])
    static func progressCompletion(clearing: Bool) async throws {
        let gate = BatchGate(), client = BatchProcessingClient()
        let protected = contact()
        let f = try BatchFixture(contacts: [contact(), protected, CNMutableContact()], gate: gate,
                                 processingTask: ContactProcessingTask(client: client))
        defer { gate.open(); f.cleanup() }
        f.defaults.set([protected.identifier], forKey: kWhitelistIdentifiersKey)
        let run = Task { await f.run(clearing: clearing) }
        try await waitUntil { gate.entered && client.attached }
        gate.open()
        #expect(await run.value == .completed)
        #expect(client.updates.map(\.checked) == client.updates.map(\.checked).sorted())
        #expect(Set(client.updates.map(\.checked)) == [0, 1, 2, 3])
        #expect(client.updates.last?.checked == 3 && client.updates.last?.total == 3)
        #expect(client.completions == [true] && f.source.writes == 1)
        #expect(try await f.history.versions().first?.status == .completed)
    }

    @Test("Low-background-time warnings occur once per operation despite skips and rejected concurrent work", arguments: [false, true])
    static func backgroundWarningOnce(clearing: Bool) async throws {
        let gate = BatchGate(), environment = BatchNotificationEnvironment()
        let protected = contact()
        let f = try BatchFixture(contacts: [contact(), contact(), contact(), protected, CNMutableContact()],
                                 gate: gate, pauseAfterWrite: true, pauseWriteNumber: 2, notificationEnvironment: environment)
        defer { gate.open(); f.cleanup() }
        f.defaults.set([protected.identifier], forKey: kWhitelistIdentifiersKey)
        let run = Task { await f.run(clearing: clearing) }
        try await waitUntil { gate.entered && environment.notifications == [lowTimeWarning] }
        #expect(await f.run(clearing: !clearing) == .failed(.busy))
        gate.open()
        #expect(await run.value == .completed)
        #expect(environment.notifications == [lowTimeWarning, completionNotice])
        #expect(await f.run(clearing: clearing) == .completed)
        #expect(environment.notifications == [lowTimeWarning, completionNotice, lowTimeWarning, completionNotice])
        #expect(f.source.writes == 3)
    }

    @Test("Foreground and inactive processing never submit background warnings", arguments: [UIApplication.State.active, .inactive])
    static func foregroundDoesNotWarn(state: UIApplication.State) async throws {
        let environment = BatchNotificationEnvironment()
        environment.state = state
        let f = try BatchFixture(contacts: [contact(), CNMutableContact()], notificationEnvironment: environment)
        defer { f.cleanup() }
        #expect(await f.run(clearing: false) == .completed)
        #expect(environment.notifications.isEmpty && f.source.writes == 1)
    }

    @Test("Adequate background time suppresses warnings without suppressing completion", arguments: [10.0, 60.0])
    static func adequateBackgroundTime(remainingTime: Double) async throws {
        let environment = BatchNotificationEnvironment()
        environment.remainingTime = remainingTime
        let f = try BatchFixture(contacts: [contact(), CNMutableContact()], notificationEnvironment: environment)
        defer { f.cleanup() }
        #expect(await f.run(clearing: false) == .completed)
        #expect(environment.notifications == [completionNotice])
    }

    @Test("Native processing owns notifications after attaching, even with low UIKit background time", arguments: [false, true])
    static func nativeTaskSuppressesWarnings(clearing: Bool) async throws {
        let gate = BatchGate(), client = BatchProcessingClient(), environment = BatchNotificationEnvironment()
        let f = try BatchFixture(contacts: [contact(), CNMutableContact()], gate: gate,
                                 processingTask: ContactProcessingTask(client: client), notificationEnvironment: environment)
        defer { gate.open(); f.cleanup() }
        let run = Task { await f.run(clearing: clearing) }
        try await waitUntil { gate.entered && client.attached }
        gate.open()
        #expect(await run.value == .completed)
        #expect(environment.notifications.isEmpty && client.completions == [true])
    }

    @Test("Foreground progress advances once per checked contact, including trailing skips", arguments: [false, true])
    static func foregroundProgress(clearing: Bool) async throws {
        let protected = contact()
        let f = try BatchFixture(contacts: [contact(), protected, CNMutableContact(), CNMutableContact()])
        defer { f.cleanup() }
        f.defaults.set([protected.identifier], forKey: kWhitelistIdentifiersKey)
        var updates: [(String?, Double)] = []
        let outcome = await f.run(clearing: clearing) { updates.append(($0, $1)) }
        #expect(outcome == .completed)
        #expect(updates.map { $0.1 } == [25, 50, 75, 100])
        #expect(updates.map { $0.0 } == Array(repeating: clearing ? nil : "Lin Mu Qing", count: 4))
        #expect(f.source.writes == 1)
    }

    @Test("All-whitelisted batches report foreground progress without producing result text", arguments: [false, true])
    static func allWhitelistedProgress(clearing: Bool) async throws {
        let contacts = [contact(), contact()]
        let f = try BatchFixture(contacts: contacts)
        defer { f.cleanup() }
        f.defaults.set(contacts.map(\.identifier), forKey: kWhitelistIdentifiersKey)
        var updates: [(String?, Double)] = []
        #expect(await f.run(clearing: clearing) { updates.append(($0, $1)) } == .completed)
        #expect(updates.map { $0.1 } == [50, 100] && updates.allSatisfy { $0.0 == nil })
        #expect(f.source.writes == 0)
        #expect(try await f.history.versions().isEmpty)
    }

    @Test("Company conversion reports its result and trailing empty contacts keep it visible")
    static func companyProgress() async throws {
        let company = CNMutableContact()
        company.organizationName = "林"
        let f = try BatchFixture(contacts: [company, CNMutableContact()])
        defer { f.cleanup() }
        f.defaults.set(true, forKey: kMassageCompanyKey)
        var updates: [(String?, Double)] = []
        #expect(await f.run(clearing: false) { updates.append(($0, $1)) } == .completed)
        #expect(updates.map { $0.1 } == [50, 100])
        #expect(updates.map { $0.0 } == ["Lin", "Lin"] && f.source.writes == 1)
    }

    @Test("Empty batches finish at 100 percent in AppState", arguments: [false, true])
    static func emptyBatchCompletion(clearing: Bool) async throws {
        let f = try BatchFixture(contacts: [])
        defer { f.cleanup() }
        let state = AppState(contactProvider: { f.engine }, requestAccess: { true }, announce: { _ in }, waitForCompletion: {})
        if clearing {
            state.performClean()
        } else {
            state.execute()
        }
        try await waitUntil { state.lastOutcome == .completed && !state.isProcessing }
        #expect(state.percentage == 100 && state.statusText == ContactOperationOutcome.completed.status)
        #expect(f.source.writes == 0)
    }

    @Test("A partial batch failure keeps actual foreground progress instead of forcing 100 percent")
    static func partialFailureProgress() async throws {
        let f = try BatchFixture(contacts: [contact(), contact(), contact(), contact()], failWrite: 2)
        defer { f.cleanup() }
        let state = AppState(contactProvider: { f.engine }, requestAccess: { true }, announce: { _ in }, waitForCompletion: {})
        state.execute()
        try await waitUntil { state.lastOutcome != nil && !state.isProcessing }
        #expect(state.lastOutcome == .failed(.saveFailed) && state.percentage == 25)
        #expect(f.source.writes == 1)
    }

    @Test("Editor saves use the injected history and release the engine for subsequent batches")
    static func editorHistory() async throws {
        let original = contact(), modified = try #require(original.mutableCopy() as? CNMutableContact)
        modified.nickname = "Edited nickname"
        let f = try BatchFixture(contacts: [original])
        defer { f.cleanup() }
        #expect(await f.engine.saveEditedContact(original: original, modified: modified) == .completed)
        #expect(!f.engine.isProcessing && f.source.writes == 1)
        #expect(try await f.history.versions().first?.kind == .editContact)
        #expect(await f.run(clearing: false) == .completed)
        #expect(try f.source.read(identifier: original.identifier, fields: [])?.nickname == "Edited nickname")
        #expect(try await f.history.versions().count == 2)
    }

    @Test("Restoring a selected field through the engine records a version and reports progress")
    static func restoreHistory() async throws {
        let original = contact()
        let f = try BatchFixture(contacts: [original])
        defer { f.cleanup() }
        #expect(await f.run(clearing: false) == .completed)
        let preview = try await f.history.preview(targetOrdinal: 0)
        let selected = try #require(preview.entries.first { $0.change.field == .phoneticGivenName })
        var updates: [(Int, Int)] = []
        let result = await f.engine.restoreVersion(preview, selected: [selected.id]) { updates.append(($0, $1)) }
        #expect(result.0 == .completed && result.1 == 0 && !f.engine.isProcessing)
        #expect(updates.count == 1 && updates.first?.0 == 1 && updates.first?.1 == 1)
        let saved = try #require(try f.source.read(identifier: original.identifier, fields: []))
        #expect(saved.phoneticGivenName == "Original given" && saved.phoneticFamilyName == "Lin" && saved.nickname == "LMQ")
        let version = try #require(try await f.history.versions().first)
        #expect(version.kind == .restore && version.targetOrdinal == 0 && version.fieldCount == 1 && version.status == .completed)
    }

    private static func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(5)
        while !condition(), ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(5))
        }
        try #require(condition(), "Batch worker did not reach the expected save/enumeration boundary")
    }
}
