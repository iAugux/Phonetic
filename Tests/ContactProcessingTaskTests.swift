@testable import Phonetic
import Foundation
import Testing

@MainActor
private final class ProcessingTaskClient: ContinuedProcessingClient {
    struct Update {
        let id: String
        let checked: Int64
        let total: Int64
        let subtitle: String
    }

    var preparationSucceeds = true
    var submissionFails = false
    var holdSubmission = false
    var submissions: [String] = []
    private var pendingSubmissions: [String: CheckedContinuation<Void, any Error>] = [:]
    var updates: [Update] = []
    var completions: [(String, Bool)] = []
    var cancellations: [String] = []
    var onLaunch: (@MainActor (String) -> Void)?
    var onExpiration: (@MainActor (String) -> Void)?

    func prepare(onLaunch: @escaping @MainActor (String) -> Void, onExpiration: @escaping @MainActor (String) -> Void) -> Bool {
        self.onLaunch = onLaunch
        self.onExpiration = onExpiration
        return preparationSucceeds
    }

    func submit(id: String, title: String, subtitle: String) async throws {
        submissions.append(id)
        if holdSubmission {
            try await withCheckedThrowingContinuation { pendingSubmissions[id] = $0 }
        }
        if submissionFails {
            throw NSError(domain: "TestScheduler", code: 1)
        }
    }

    func resolveSubmission(id: String) {
        pendingSubmissions.removeValue(forKey: id)?.resume()
    }

    func resolveAllSubmissions() {
        let pending = pendingSubmissions.values
        pendingSubmissions.removeAll()
        for completion in pending {
            completion.resume()
        }
    }

    func update(id: String, checked: Int64, total: Int64, title: String, subtitle: String) {
        updates.append(Update(id: id, checked: checked, total: total, subtitle: subtitle))
    }

    func complete(id: String, success: Bool) {
        completions.append((id, success))
    }

    func cancelRequest(id: String) {
        cancellations.append(id)
    }
}

@MainActor
private final class ProcessingWork {
    private var completion: CheckedContinuation<ContactOperationOutcome, Never>?
    private(set) var starts = 0
    private(set) var cancellations = 0

    func run() async -> ContactOperationOutcome {
        starts += 1
        return await withCheckedContinuation { completion = $0 }
    }

    func cancel() {
        cancellations += 1
    }

    func finish(_ outcome: ContactOperationOutcome = .completed) {
        completion?.resume(returning: outcome)
        completion = nil
    }
}

@MainActor
struct ContactProcessingTaskTests {
    @Test("Processing never waits for a system launch, including silent submission rejection")
    static func noLaunch() async throws {
        let client = ProcessingTaskClient(), work = ProcessingWork()
        let manager = ContactProcessingTask(client: client)
        let run = Task { await manager.run(operation: .addPinyin, onCancel: work.cancel, work: work.run) }
        defer { manager.cancel(); work.finish(.stopped) }
        try await waitUntil { client.submissions.count == 1 && work.starts == 1 }
        let id = try #require(client.submissions.first)
        manager.update(checked: 3, total: 3)
        #expect(!manager.isUsingSystemTask && client.updates.isEmpty)
        work.finish()
        #expect(await run.value == .completed)
        #expect(client.cancellations == [id] && client.completions.isEmpty)
        client.onLaunch?(id)
        #expect(work.starts == 1 && client.completions.first?.1 == true)
        #expect(client.updates.last?.checked == 3 && client.updates.last?.total == 3)
        #expect(client.updates.last?.subtitle == String(localized: "Completed"))
    }

    @Test("A delayed submission completion cannot block finishing or leave a late request queued")
    static func delayedSubmission() async throws {
        let client = ProcessingTaskClient(), work = ProcessingWork()
        client.holdSubmission = true
        let manager = ContactProcessingTask(client: client)
        let run = Task { await manager.run(operation: .restore, onCancel: work.cancel, work: work.run) }
        defer { manager.cancel(); work.finish(.stopped); client.resolveAllSubmissions() }
        try await waitUntil { client.submissions.count == 1 && work.starts == 1 }
        let id = try #require(client.submissions.first)
        work.finish()
        #expect(await run.value == .completed)
        #expect(client.cancellations == [id])
        client.resolveSubmission(id: id)
        try await waitUntil { client.cancellations.count == 2 }
        #expect(client.cancellations == [id, id] && work.starts == 1)
    }

    @Test("Older systems and unavailable schedulers process without native task UI", arguments: [false, true])
    static func unavailableScheduler(hasClient: Bool) async {
        let client = ProcessingTaskClient()
        client.preparationSucceeds = false
        let manager = ContactProcessingTask(client: hasClient ? client : nil)
        var starts = 0
        let outcome = await manager.run(operation: .clearFields, onCancel: {}) { starts += 1; return .completed }
        #expect(outcome == .completed && starts == 1 && !manager.isUsingSystemTask)
        #expect(client.submissions.isEmpty && client.completions.isEmpty)
    }

    @Test("Submission failure never restarts or interrupts contact work", arguments: [false, true])
    static func rejectedSubmission(afterLaunch: Bool) async throws {
        let client = ProcessingTaskClient(), work = ProcessingWork()
        client.submissionFails = true
        client.holdSubmission = afterLaunch
        let manager = ContactProcessingTask(client: client)
        let run = Task { await manager.run(operation: .addPinyin, onCancel: work.cancel, work: work.run) }
        defer { manager.cancel(); work.finish(.stopped); client.resolveAllSubmissions() }
        try await waitUntil { client.submissions.count == 1 && work.starts == 1 }
        let id = try #require(client.submissions.first)
        if afterLaunch {
            client.onLaunch?(id)
            client.resolveSubmission(id: id)
        }
        work.finish()
        #expect(await run.value == .completed)
        #expect(work.starts == 1 && work.cancellations == 0)
        #expect(client.completions.count == (afterLaunch ? 1 : 0))
    }

    @Test("Late native attachment uses current progress and never starts a second worker")
    static func successfulTask() async throws {
        let client = ProcessingTaskClient(), work = ProcessingWork()
        let manager = ContactProcessingTask(client: client)
        var attachments = 0
        let run = Task {
            await manager.run(operation: .addPinyin, onCancel: work.cancel,
                              onSystemTaskAttached: { attachments += 1 }, work: work.run)
        }
        defer { manager.cancel(); work.finish(.stopped) }
        try await waitUntil { client.submissions.count == 1 && work.starts == 1 }
        let id = try #require(client.submissions.first)
        #expect(id.hasPrefix(ContactProcessingTask.identifierPrefix + "."))
        manager.update(checked: 4, total: 10)
        manager.update(checked: 2, total: 10)
        #expect(client.updates.isEmpty)
        client.onLaunch?(id)
        client.onLaunch?(id)
        #expect(manager.isUsingSystemTask && attachments == 1 && work.starts == 1)
        #expect(client.updates.last?.checked == 4 && client.updates.last?.total == 10)
        manager.update(checked: 7, total: 10)
        #expect(client.updates.last?.checked == 7)
        work.finish()
        #expect(await run.value == .completed)
        #expect(client.completions.count == 1 && client.completions.first?.1 == true)
        #expect(client.updates.last?.checked == 10 && client.updates.last?.total == 10)
        #expect(client.updates.last?.subtitle == String(localized: "Completed"))
        #expect(!manager.isUsingSystemTask)
        manager.update(checked: 99, total: 99)
        client.onExpiration?(id)
        #expect(client.completions.count == 1 && work.cancellations == 0)
    }

    @Test("A failed operation preserves partial progress, even when the system launches after failure", arguments: [false, true])
    static func failedOperation(lateLaunch: Bool) async throws {
        let client = ProcessingTaskClient(), work = ProcessingWork()
        let manager = ContactProcessingTask(client: client)
        let run = Task { await manager.run(operation: .restore, onCancel: work.cancel, work: work.run) }
        defer { manager.cancel(); work.finish(.stopped) }
        try await waitUntil { client.submissions.count == 1 && work.starts == 1 }
        let id = try #require(client.submissions.first)
        manager.update(checked: 1, total: 3)
        if !lateLaunch {
            client.onLaunch?(id)
        }
        work.finish(.failed(.saveFailed))
        #expect(await run.value == .failed(.saveFailed))
        if lateLaunch {
            client.onLaunch?(id)
        }
        #expect(client.completions.first?.1 == false && client.updates.last?.checked == 1)
        #expect(client.updates.last?.total == 3 && work.starts == 1)
        #expect(client.updates.last?.subtitle == ContactOperationOutcome.failed(.saveFailed).status)
    }

    @Test("System stop waits for cooperative write and journal finalization before completing")
    static func systemCancellation() async throws {
        let client = ProcessingTaskClient(), work = ProcessingWork()
        let manager = ContactProcessingTask(client: client)
        let run = Task { await manager.run(operation: .clearFields, onCancel: work.cancel, work: work.run) }
        defer { manager.cancel(); work.finish(.stopped) }
        try await waitUntil { client.submissions.count == 1 && work.starts == 1 }
        let id = try #require(client.submissions.first)
        client.onLaunch?(id)
        manager.update(checked: 4, total: 10)
        client.onExpiration?(id)
        client.onExpiration?(id)
        #expect(work.cancellations == 1 && client.completions.isEmpty)
        let busy = await manager.run(operation: .restore, onCancel: {}) {
            Issue.record("A cancelled worker must finish before another operation can start")
            return .completed
        }
        #expect(busy == .failed(.busy))
        manager.update(checked: 10, total: 10)
        work.finish()
        #expect(await run.value == .stopped)
        #expect(client.completions.count == 1 && client.completions.first?.1 == false)
        #expect(client.updates.last?.checked == 4 && client.updates.last?.total == 10)
        #expect(client.updates.last?.subtitle == String(localized: "Stopped"))
    }

    @Test("A late native launch protects cancelled work until finalization returns",
          arguments: [false, true], [ContactOperationOutcome.completed, .failed(.historyUnavailable)])
    static func cancellationBeforeLaunch(submissionPending: Bool, outcome: ContactOperationOutcome) async throws {
        let client = ProcessingTaskClient(), work = ProcessingWork()
        client.holdSubmission = submissionPending
        let manager = ContactProcessingTask(client: client)
        var attachments = 0
        let run = Task {
            await manager.run(operation: .addPinyin, onCancel: work.cancel,
                              onSystemTaskAttached: { attachments += 1 }, work: work.run)
        }
        defer { manager.cancel(); work.finish(.stopped); client.resolveAllSubmissions() }
        try await waitUntil { client.submissions.count == 1 && work.starts == 1 }
        let id = try #require(client.submissions.first)
        manager.update(checked: 4, total: 10)
        manager.cancel()
        client.onLaunch?(id)
        client.onLaunch?(id)
        client.onExpiration?(id)
        #expect(manager.isUsingSystemTask && attachments == 1)
        #expect(work.starts == 1 && work.cancellations == 1)
        #expect(client.cancellations == [id] && client.completions.isEmpty)
        #expect(client.updates.last?.checked == 4 && client.updates.last?.total == 10)
        if submissionPending {
            client.resolveSubmission(id: id)
            try await waitUntil { client.cancellations.count == 2 }
            #expect(manager.isUsingSystemTask && client.completions.isEmpty)
        }
        let busy = await manager.run(operation: .restore, onCancel: {}) {
            Issue.record("Late attachment must not release a worker still finalizing")
            return .completed
        }
        #expect(busy == .failed(.busy))
        manager.update(checked: 10, total: 10)
        work.finish(outcome)
        let expected = outcome.succeeded ? ContactOperationOutcome.stopped : outcome
        #expect(await run.value == expected)
        #expect(!manager.isUsingSystemTask && attachments == 1)
        #expect(client.completions.count == 1 && client.completions.first?.1 == false)
        #expect(client.updates.last?.checked == 4 && client.updates.last?.subtitle == expected.status)
    }

    @Test("Caller cancellation stops running work with or without a system scheduler", arguments: [false, true])
    static func parentCancellation(hasClient: Bool) async throws {
        let client = ProcessingTaskClient(), work = ProcessingWork()
        let manager = ContactProcessingTask(client: hasClient ? client : nil)
        let run = Task { await manager.run(operation: .addPinyin, onCancel: work.cancel, work: work.run) }
        defer { manager.cancel(); work.finish(.stopped) }
        try await waitUntil { work.starts == 1 && (!hasClient || client.submissions.count == 1) }
        run.cancel()
        try await waitUntil { work.cancellations == 1 }
        work.finish()
        #expect(await run.value == .stopped)
        #expect(client.cancellations == client.submissions && work.starts == 1)
    }

    @Test("Old launch, expiration and submission callbacks cannot affect a newer operation")
    static func consecutiveTasks() async throws {
        let client = ProcessingTaskClient(), oldWork = ProcessingWork(), newWork = ProcessingWork()
        client.holdSubmission = true
        let manager = ContactProcessingTask(client: client)
        let oldRun = Task { await manager.run(operation: .addPinyin, onCancel: oldWork.cancel, work: oldWork.run) }
        defer { manager.cancel(); oldWork.finish(.stopped); newWork.finish(.stopped); client.resolveAllSubmissions() }
        try await waitUntil { client.submissions.count == 1 && oldWork.starts == 1 }
        let oldID = try #require(client.submissions.first)
        manager.cancel()
        oldWork.finish()
        #expect(await oldRun.value == .stopped)
        let newRun = Task { await manager.run(operation: .clearFields, onCancel: newWork.cancel, work: newWork.run) }
        try await waitUntil { client.submissions.count == 2 && newWork.starts == 1 }
        let newID = try #require(client.submissions.last)
        #expect(oldID != newID)
        client.onLaunch?(oldID)
        client.onExpiration?(oldID)
        client.resolveSubmission(id: oldID)
        try await waitUntil { client.cancellations.filter { $0 == oldID }.count == 2 }
        #expect(oldWork.starts == 1 && newWork.starts == 1 && newWork.cancellations == 0)
        #expect(!manager.isUsingSystemTask && !client.cancellations.contains(newID))
        client.onLaunch?(newID)
        client.onExpiration?(oldID)
        #expect(newWork.cancellations == 0 && manager.isUsingSystemTask)
        newWork.finish()
        #expect(await newRun.value == .completed)
        #expect(client.completions.last?.0 == newID && client.completions.last?.1 == true)
    }

    @Test("A concurrent operation cannot replace an active worker")
    static func busyOperation() async throws {
        let work = ProcessingWork()
        let manager = ContactProcessingTask(client: nil)
        let run = Task { await manager.run(operation: .addPinyin, onCancel: work.cancel, work: work.run) }
        defer { manager.cancel(); work.finish(.stopped) }
        try await waitUntil { work.starts == 1 }
        let busy = await manager.run(operation: .clearFields, onCancel: {}) {
            Issue.record("A second operation started while the first was active")
            return .completed
        }
        #expect(busy == .failed(.busy) && work.starts == 1 && work.cancellations == 0)
        work.finish()
        #expect(await run.value == .completed)
    }

    @Test("Empty contact sets have valid progress units and finish successfully")
    static func emptyContacts() async throws {
        let client = ProcessingTaskClient(), work = ProcessingWork()
        let manager = ContactProcessingTask(client: client)
        let run = Task { await manager.run(operation: .addPinyin, onCancel: work.cancel, work: work.run) }
        defer { manager.cancel(); work.finish(.stopped) }
        try await waitUntil { client.submissions.count == 1 && work.starts == 1 }
        manager.update(checked: 0, total: 0)
        try client.onLaunch?(#require(client.submissions.first))
        #expect(client.updates.first?.checked == 0 && client.updates.first?.total == 1)
        work.finish()
        #expect(await run.value == .completed)
        #expect(client.updates.last?.checked == 1 && client.completions.first?.1 == true)
    }

    @Test("A caller already cancelled never submits a request or starts contact writes")
    static func initiallyCancelled() async {
        let client = ProcessingTaskClient(), work = ProcessingWork()
        let manager = ContactProcessingTask(client: client)
        let run = Task { await manager.run(operation: .addPinyin, onCancel: work.cancel, work: work.run) }
        run.cancel()
        #expect(await run.value == .stopped)
        #expect(client.submissions.isEmpty && work.starts == 0 && work.cancellations == 1)
    }
}
