@testable import Phonetic
import Foundation
import Testing
import UIKit

@MainActor
private final class ProcessingService: ContactProcessingService {
    var isProcessing = true {
        didSet {
            if !isProcessing {
                stopWrites += 1
            }
        }
    }

    private(set) var stopWrites = 0
    private(set) var starts = 0
    var messageOfCurrentKeysNeedToBeCleaned: String {
        "Test fields"
    }

    private var resultHandler: PhoneticContacts.ResultHandler?
    private var completion: CheckedContinuation<ContactOperationOutcome, Never>?

    func execute(resultHandler: @escaping PhoneticContacts.ResultHandler) async -> ContactOperationOutcome {
        starts += 1
        self.resultHandler = resultHandler
        return await withCheckedContinuation { completion = $0 }
    }

    func cleanMandarinLatinPhonetic(resultHandler: @escaping PhoneticContacts.ResultHandler) async -> ContactOperationOutcome {
        await execute(resultHandler: resultHandler)
    }

    func progress(_ percentage: Double) {
        resultHandler?(nil, percentage)
    }

    func finish(aborted: Bool) {
        finish(outcome: aborted ? .stopped : .completed)
    }

    func finish(outcome: ContactOperationOutcome) {
        completion?.resume(returning: outcome)
        completion = nil
        resultHandler = nil
    }
}

@MainActor
private final class CompletionDelay {
    private var continuation: CheckedContinuation<Void, Never>?
    private var released = false
    var waiting: Bool {
        continuation != nil
    }

    func wait() async {
        guard !released else { return }
        await withCheckedContinuation { continuation = $0 }
    }

    func release() {
        released = true
        continuation?.resume()
        continuation = nil
    }
}

@MainActor
struct AppStateTests {
    @Test("Processing failures expose an actionable error instead of reporting completion")
    static func failedProcessing() async throws {
        let engine = ProcessingService(), delay = CompletionDelay()
        let state = state(engine: engine, delay: delay)
        defer { engine.finish(aborted: true); delay.release() }
        state.execute()
        try await waitUntil { engine.starts == 1 }
        engine.progress(40)
        engine.finish(outcome: .failed(.historyUnavailable))
        try await waitUntil { delay.waiting }
        #expect(state.showProcessingError && state.processingErrorMessage == ContactVersionError.historyUnavailable.localizedDescription)
        #expect(state.lastOutcome == .failed(.historyUnavailable))
        #expect(state.percentage == 40 && state.statusText == ContactOperationOutcome.failed(.historyUnavailable).status)
        delay.release()
        try await waitUntil { !state.isProcessing }
        #expect(state.percentage == 40 && state.statusText == ContactOperationOutcome.failed(.historyUnavailable).status)
    }

    private static func state(engine: ProcessingService, delay: CompletionDelay, requestAccess: @escaping @MainActor () async -> Bool = { true }, announce: @escaping @MainActor (String) -> Void = { _ in }) -> AppState {
        AppState(contactProvider: { engine }, requestAccess: requestAccess, announce: announce,
                 waitForCompletion: { await delay.wait() }, dismissPresentedModals: { $0() })
    }

    @Test("Completion blocks new work and keeps final progress through dismissal")
    static func completionLifecycle() async throws {
        let engine = ProcessingService(), delay = CompletionDelay()
        var announcements: [String] = []
        let state = state(engine: engine, delay: delay, announce: { announcements.append($0) })
        #expect(state.lastOutcome == nil)
        defer { engine.finish(aborted: true); delay.release() }

        state.execute()
        try await waitUntil { engine.starts == 1 }
        #expect(state.canAbortProcessing)
        state.execute()
        #expect(state.showAbortAlert)
        engine.progress(100)
        engine.finish(aborted: false)
        try await waitUntil { delay.waiting }
        #expect(state.isProcessing && state.isShowingCompletion && !state.canAbortProcessing)
        #expect(!state.showAbortAlert)
        #expect(announcements == [String(localized: "Completed")])
        #expect(state.lastOutcome == .completed)

        state.execute()
        state.clean()
        state.performClean()
        state.abort()
        #expect(engine.starts == 1 && engine.stopWrites == 0)
        #expect(!state.showAbortAlert && !state.showCleanAlert)

        delay.release()
        try await waitUntil { !state.isProcessing }
        #expect(!state.isShowingCompletion && state.percentage == 100)
        #expect(state.lastOutcome == .completed)
    }

    @Test("Cleaning cancellation retains the completed progress and result")
    static func cleanCancellation() async throws {
        let engine = ProcessingService(), delay = CompletionDelay()
        let state = state(engine: engine, delay: delay)
        defer { engine.finish(aborted: true); delay.release() }

        state.performClean()
        try await waitUntil { engine.starts == 1 }
        #expect(state.canAbortProcessing && state.percentage == 0)
        engine.progress(25)
        #expect(state.percentage == 25)
        state.abort()
        #expect(engine.stopWrites == 1)
        engine.finish(aborted: true)
        try await waitUntil { delay.waiting }
        #expect(!state.canAbortProcessing && state.percentage == 25)
        delay.release()
        try await waitUntil { !state.isProcessing }
        #expect(!state.isShowingCompletion && state.percentage == 25)
        #expect(state.statusText == ContactOperationOutcome.stopped.status)
        #expect(state.lastOutcome == .stopped)
    }

    @Test("Successful cleaning finishes at full progress and keeps its result until the next operation")
    static func cleanCompletion() async throws {
        let engine = ProcessingService(), delay = CompletionDelay()
        let state = state(engine: engine, delay: delay)
        defer { engine.finish(aborted: true); delay.release() }

        state.performClean()
        try await waitUntil { engine.starts == 1 }
        engine.progress(25)
        // Skipped contacts may not produce another progress event before the operation returns.
        engine.finish(aborted: false)
        try await waitUntil { delay.waiting }
        #expect(state.percentage == 100 && state.statusText == ContactOperationOutcome.completed.status)
        delay.release()
        try await waitUntil { !state.isProcessing }
        #expect(state.statusText == ContactOperationOutcome.completed.status)

        state.performClean()
        #expect(state.isProcessing && state.percentage == 0)
        #expect(state.statusText == String(localized: "Processing…"))
        #expect(state.lastOutcome == .completed)
        try await waitUntil { engine.starts == 2 }
        engine.finish(aborted: true)
        try await waitUntil { !state.isProcessing }
    }

    @Test("Unsupported links do not dismiss modals or start contact work")
    static func unsupportedLinks() throws {
        let engine = ProcessingService(), delay = CompletionDelay()
        let state = state(engine: engine, delay: delay)
        state.showSettings = true
        state.showAdditionalSettings = true
        state.showWalkthrough = true
        state.showChooseQuickSearchAlert = true
        state.showCleanAlert = true
        state.showAbortAlert = true
        var navigationCompleted = false

        #expect(try !state.handleOpenURL(#require(URL(string: "phonetic://activity"))) { navigationCompleted = true })
        #expect(!navigationCompleted)
        #expect(state.showSettings && state.showAdditionalSettings && state.showWalkthrough)
        #expect(state.showChooseQuickSearchAlert && state.showCleanAlert && state.showAbortAlert)
        #expect(engine.starts == 0 && !state.isProcessing)
        #expect(try !state.handleOpenURL(#require(URL(string: "https://activity"))))
        #expect(try !state.handleOpenURL(#require(URL(string: "phonetic://unknown"))))
    }

    @Test("Denied permission never starts contact processing or cleaning")
    static func deniedPermission() async throws {
        let engine = ProcessingService(), delay = CompletionDelay()
        var accessRequests = 0
        let state = state(engine: engine, delay: delay, requestAccess: { accessRequests += 1; return false })
        state.execute()
        try await waitUntil { accessRequests == 1 }
        state.clean()
        try await waitUntil { accessRequests == 2 }
        #expect(engine.starts == 0 && !state.isProcessing && !state.showCleanAlert)
    }

    @Test("Supported external actions clear modal state and wait for dismissal before requesting access",
          arguments: ["execute", "rollback"], [false, true])
    static func externalActionDismissal(action: String, shortcut: Bool) async throws {
        let engine = ProcessingService()
        var accessRequests = 0
        var pendingDismissal: (@MainActor () -> Void)?
        var navigationCompleted = false
        let state = AppState(contactProvider: { engine }, requestAccess: { accessRequests += 1; return false },
                             announce: { _ in }, waitForCompletion: {}, dismissPresentedModals: { pendingDismissal = $0 })
        state.showSettings = true
        state.showAdditionalSettings = true
        state.showWalkthrough = true
        state.showChooseQuickSearchAlert = true
        state.showCleanAlert = true
        state.showAbortAlert = true
        let accepted: Bool
        if shortcut {
            accepted = state.handleShortcut(UIApplicationShortcutItem(type: action, localizedTitle: action))
        } else {
            accepted = try state.handleOpenURL(#require(URL(string: "phonetic://\(action.uppercased())"))) { navigationCompleted = true }
        }
        #expect(accepted && accessRequests == 0 && engine.starts == 0 && !navigationCompleted)
        #expect(!state.showSettings && !state.showAdditionalSettings && !state.showWalkthrough)
        #expect(!state.showChooseQuickSearchAlert && !state.showCleanAlert && !state.showAbortAlert)
        let dismiss = try #require(pendingDismissal)
        dismiss()
        try await waitUntil { accessRequests == 1 }
        #expect(navigationCompleted == !shortcut)
        #expect(engine.starts == 0 && !state.isProcessing && !state.showCleanAlert)
    }

    @Test("Unknown shortcuts leave modal state untouched")
    static func unsupportedShortcut() {
        let engine = ProcessingService(), delay = CompletionDelay()
        let state = state(engine: engine, delay: delay)
        state.showSettings = true
        #expect(!state.handleShortcut(UIApplicationShortcutItem(type: "unknown", localizedTitle: "Unknown")))
        #expect(state.showSettings && engine.starts == 0)
    }
}
