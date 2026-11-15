// Created by Augus on 9/28/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import Accessibility
import Combine
import Contacts
import SwiftUI

@MainActor
protocol ContactProcessingService: AnyObject {
    var isProcessing: Bool { get set }
    var messageOfCurrentKeysNeedToBeCleaned: String { get }
    func execute(resultHandler: @escaping PhoneticContacts.ResultHandler) async -> ContactOperationOutcome
    func cleanMandarinLatinPhonetic(resultHandler: @escaping PhoneticContacts.ResultHandler) async -> ContactOperationOutcome
}

extension PhoneticContacts: ContactProcessingService {}

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isProcessing: Bool = false
    @Published private(set) var isShowingCompletion: Bool = false
    @Published var percentage: Double = 0
    @Published var statusText: String = ""
    @Published private(set) var lastOutcome: ContactOperationOutcome?

    @Published var showCleanAlert: Bool = false
    @Published var cleanAlertMessage: String = ""

    @Published var showProcessingError = false
    @Published var processingErrorMessage = ""

    @Published var showAbortAlert: Bool = false
    @Published var showChooseQuickSearchAlert: Bool = false
    @Published var showWalkthrough: Bool = false

    @Published var showSettings: Bool = false
    @Published var showAdditionalSettings: Bool = false

    private var completionTask: Task<Void, Never>?
    private let contactProvider: @MainActor () -> any ContactProcessingService
    private let requestAccess: @MainActor () async -> Bool
    private let announce: @MainActor (String) -> Void
    private let waitForCompletion: @MainActor () async throws -> Void
    private let dismissPresentedModals: @MainActor (@escaping @MainActor () -> Void) -> Void

    var canAbortProcessing: Bool {
        isProcessing && !isShowingCompletion
    }

    init(
        contactProvider: @escaping @MainActor () -> any ContactProcessingService = { PhoneticContacts.shared },
        requestAccess: @escaping @MainActor () async -> Bool = { await AppDelegate.shared.requestContactsAccess() },
        announce: @escaping @MainActor (String) -> Void = { AccessibilityNotification.Announcement($0).post() },
        waitForCompletion: @escaping @MainActor () async throws -> Void = { try await Task.sleep(for: .seconds(1)) },
        dismissPresentedModals: @escaping @MainActor (@escaping @MainActor () -> Void) -> Void = { completion in
            let rootController = UIApplication.shared.topMostViewController?.viewIfLoaded?.window?.rootViewController
            if rootController?.presentedViewController != nil {
                rootController?.dismiss(animated: false, completion: completion)
            } else {
                completion()
            }
        }
    ) {
        // Resolve the shared engine lazily to preserve notification authorization timing.
        self.contactProvider = contactProvider
        self.requestAccess = requestAccess
        self.announce = announce
        self.waitForCompletion = waitForCompletion
        self.dismissPresentedModals = dismissPresentedModals
    }

    func setup() {
        if !UserDefaults.standard.bool(forKey: displayedWalthroughKey) {
            showWalkthrough = true
        } else {
            alertToChooseQuickSearchKeyIfNeeded()
        }
    }

    func execute() {
        guard !isProcessing else {
            if canAbortProcessing {
                showAbortAlert = true
            }
            return
        }

        Task { [weak self] in
            guard let self, await self.requestAccess() else { return }
            guard !self.isProcessing else {
                if self.canAbortProcessing {
                    self.showAbortAlert = true
                }
                return
            }

            self.statusText = ""
            self.percentage = 0
            self.isProcessing = true

            let aborted = await self.contactProvider().execute { currentResult, percentage in
                self.statusText = currentResult ?? ""
                self.percentage = percentage
            }
            self.promptCompletion(aborted)
        }
    }

    func clean() {
        guard !isProcessing else {
            if canAbortProcessing {
                showAbortAlert = true
            }
            return
        }

        Task { [weak self] in
            guard let self, await self.requestAccess() else { return }
            guard !self.isProcessing else {
                if self.canAbortProcessing {
                    self.showAbortAlert = true
                }
                return
            }

            self.cleanAlertMessage = self.contactProvider().messageOfCurrentKeysNeedToBeCleaned
            self.showCleanAlert = true
        }
    }

    func performClean() {
        guard !isProcessing else { return }

        percentage = 0
        statusText = String(localized: "Processing…")
        isProcessing = true

        Task {
            let aborted = await self.contactProvider().cleanMandarinLatinPhonetic { _, percentage in
                self.percentage = percentage
            }
            self.promptCompletion(aborted)
        }
    }

    func abort() {
        guard canAbortProcessing else { return }
        contactProvider().isProcessing = false
    }

    @discardableResult
    func handleShortcut(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        debugPrint("A shortcut item was pressed: ", shortcutItem.localizedTitle)
        return handleExternalAction(shortcutItem.type)
    }

    @discardableResult
    func handleOpenURL(_ url: URL, completion: (@MainActor () -> Void)? = nil) -> Bool {
        guard let host = url.host else { return false }
        return handleExternalAction(host.lowercased(), completion: completion)
    }

    private func handleExternalAction(_ action: String, completion: (@MainActor () -> Void)? = nil) -> Bool {
        let performAction: @MainActor () -> Void
        switch action {
        case "execute":
            performAction = { self.execute() }
        case "rollback":
            performAction = { self.clean() }
        default:
            return false
        }
        dismissModals {
            performAction()
            completion?()
        }
        return true
    }

    private func dismissModals(completion: @escaping @MainActor () -> Void) {
        showSettings = false
        showAdditionalSettings = false
        showWalkthrough = false
        showChooseQuickSearchAlert = false
        showCleanAlert = false
        showAbortAlert = false

        dismissPresentedModals(completion)
    }

    private func promptCompletion(_ outcome: ContactOperationOutcome) {
        // Keep the final progress visible without offering cancellation after work has ended.
        isShowingCompletion = true
        showAbortAlert = false
        if outcome.succeeded { percentage = 100 }
        let text = outcome.status
        lastOutcome = outcome
        if case .failed(let error) = outcome {
            processingErrorMessage = error.localizedDescription
            showProcessingError = true
        }
        statusText = text
        announce(text)

        completionTask?.cancel()
        let waitForCompletion = waitForCompletion
        completionTask = Task { [weak self] in
            do {
                try await waitForCompletion()
            } catch {
                return
            }
            guard let self else { return }
            // Preserve the final text and progress through the fade-out; reset at the next start.
            self.isProcessing = false
            self.isShowingCompletion = false
            self.showAbortAlert = false
            self.completionTask = nil
        }
    }

    private func alertToChooseQuickSearchKeyIfNeeded() {
        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else { return }
        let defaults = UserDefaults.standard
        let key = "hasShownQuickSearchSetupAlert"
        let legacyKey = "ausHasLaunchedHostAppOnce"
        if defaults.object(forKey: key) == nil, defaults.bool(forKey: legacyKey) {
            defaults.set(true, forKey: key)
        }
        guard !defaults.bool(forKey: key) else { return }
        defaults.set(true, forKey: key)
        showChooseQuickSearchAlert = true
    }
}
