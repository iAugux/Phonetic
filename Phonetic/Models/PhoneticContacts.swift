// Created by Augus on 1/28/16
// Copyright © 2016 Augus <iAugux@gmail.com>

import Contacts
import os
import OSLog
import UIKit
import UserNotifications

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.iAugus.Phonetic", category: "PhoneticContacts")

/// Store APIs are thread-safe; processing state is locked and lifecycle state is main-actor isolated.
/// Remove unchecked conformance when CNContactStore and UserDefaults gain Sendable annotations.
final class PhoneticContacts: @unchecked Sendable {
    static let shared = PhoneticContacts()

    init(userDefaults: UserDefaults, contactStore: CNContactStore = CNContactStore(),
         versionStore: ContactVersionStore = .shared, processingTask: ContactProcessingTask? = nil,
         applicationState: @escaping @MainActor @Sendable () -> UIApplication.State = { UIApplication.shared.applicationState },
         backgroundTimeRemaining: @escaping @MainActor @Sendable () -> TimeInterval = { UIApplication.shared.backgroundTimeRemaining },
         notificationHandler: (@MainActor @Sendable (String) -> Void)? = nil) {
        self.userDefaults = userDefaults
        self.contactStore = contactStore
        self.versionStore = versionStore
        self.injectedProcessingTask = processingTask
        self.applicationState = applicationState
        self.backgroundTimeRemaining = backgroundTimeRemaining
        self.notificationHandler = notificationHandler
    }

    private convenience init() {
        self.init(userDefaults: .standard)
        logger.debug("Register notifications")
        // register user notification settings
        Task { @MainActor in
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                logger.debug("Notification authorization granted: \(granted)")
            } catch {
                logger.error("Notification authorization failed: \(error.localizedDescription)")
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(reinstateBackgroundTask), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    let contactStore: CNContactStore
    let userDefaults: UserDefaults
    private let versionStore: ContactVersionStore
    private let injectedProcessingTask: ContactProcessingTask?
    private let applicationState: @MainActor @Sendable () -> UIApplication.State
    private let backgroundTimeRemaining: @MainActor @Sendable () -> TimeInterval
    private let notificationHandler: (@MainActor @Sendable (String) -> Void)?
    @MainActor private var processingTask: ContactProcessingTask {
        injectedProcessingTask ?? .shared
    }

    @MainActor var contactsTotalCount: Int = 0
    var keysToFetch: [String] {
        var keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneticGivenNameKey, CNContactPhoneticFamilyNameKey, CNContactOrganizationNameKey]
        if let quickSearchKey = ContactKeyForQuickSearch {
            keys.append(quickSearchKey)
        }
        keys.append(contentsOf: keysToFetchIfNeeded)
        return keys
    }

    private let processing = OSAllocatedUnfairLock(initialState: false)

    @MainActor var isProcessing: Bool {
        get { processing.withLock { $0 } }
        set {
            processing.withLock { $0 = newValue }
            if newValue {
                registerBackgroundTask()
            } else {
                processingTask.cancel()
                endBackgroundTask()
            }
        }
    }

    @MainActor private var operationInFlight = false
    @MainActor private var didWarnAboutBackgroundTime = false

    @MainActor private var backgroundTask = UIBackgroundTaskIdentifier.invalid
    @MainActor private var backgroundTaskToken: UUID?

    typealias ResultHandler = @MainActor @Sendable (_ currentResult: String?, _ percentage: Double) -> Void

    private enum ProcessingEvent: Sendable {
        case count(Int)
        case visited(checked: Int, total: Int)
        case result(String)
    }

    @MainActor func execute(resultHandler: @escaping ResultHandler) async -> ContactOperationOutcome {
        await processContacts(clearing: false, resultHandler: resultHandler)
    }

    @MainActor func cleanMandarinLatinPhonetic(resultHandler: @escaping ResultHandler) async -> ContactOperationOutcome {
        await processContacts(clearing: true, resultHandler: resultHandler)
    }

    @MainActor private func processContacts(clearing: Bool, resultHandler: @escaping ResultHandler) async -> ContactOperationOutcome {
        await performVersionedOperation(kind: clearing ? .clearFields : .addPinyin, operation: clearing ? .clearFields : .addPinyin) { session in
            await self.processContactEvents(clearing: clearing, session: session, task: self.processingTask, resultHandler: resultHandler)
        }
    }

    @MainActor private func performVersionedOperation(kind: ContactVersionKind, operation: ContactProcessingOperation,
                                                      preview: ContactRestorePreview? = nil, work: @escaping @MainActor (ContactVersionSession) async -> ContactOperationOutcome) async -> ContactOperationOutcome {
        guard !operationInFlight else { return .failed(.busy) }
        operationInFlight = true
        didWarnAboutBackgroundTime = false
        isProcessing = true
        defer { operationInFlight = false; isProcessing = false }
        let store = versionStore
        let session: ContactVersionSession
        do {
            session = try await store.begin(kind: kind, targetOrdinal: preview?.targetOrdinal,
                                            expectedHead: preview?.headID, checkHead: preview != nil)
        } catch { return .failed((error as? ContactVersionError) ?? .historyUnavailable) }
        let task = processingTask
        var usedSystemTask = false
        var finalized = false
        let recordedWork: @MainActor () async -> ContactOperationOutcome = {
            // A system task can attach while contact work or journal finalization is already running.
            defer { usedSystemTask = kind != .editContact && task.isUsingSystemTask }
            let result = await work(session)
            let outcome: ContactOperationOutcome = result.succeeded && (Task.isCancelled || !self.processing.withLock { $0 }) ? .stopped : result
            finalized = true
            do { try await store.finish(session, outcome: outcome) } catch { return .failed(.historyUnavailable) }
            return outcome
        }
        let outcome: ContactOperationOutcome = if kind == .editContact {
            // A single-contact save does not need a system background-progress presentation.
            await recordedWork()
        } else {
            await task.run(operation: operation, onCancel: {
                self.processing.withLock { $0 = false }
            }, onSystemTaskAttached: {
                self.endBackgroundTask()
            }, work: recordedWork)
        }
        // A cancelled scheduler request may never launch its work closure.
        if !finalized {
            do { try await store.finish(session, outcome: outcome) } catch { return .failed(.historyUnavailable) }
        }
        handlingCompletion(aborted: !outcome.succeeded, usedSystemTask: usedSystemTask)
        return outcome
    }

    @MainActor func saveEditedContact(original: CNContact, modified: CNContact) async -> ContactOperationOutcome {
        let edit: ContactVersionEdit
        do { edit = try ContactVersionSession.edit(original: original, modified: modified) } catch { return .failed(.historyUnavailable) }
        return await performVersionedOperation(kind: .editContact, operation: .editContact) { session in
            guard !Task.isCancelled, self.processing.withLock({ $0 }) else { return .stopped }
            do { try await self.versionStore.saveEdit(edit, session: session); return .completed } catch { return .failed((error as? ContactVersionError) ?? .saveFailed) }
        }
    }

    @MainActor func restoreVersion(_ preview: ContactRestorePreview, selected: Set<String>, progress: @escaping @MainActor (Int, Int) -> Void) async -> (ContactOperationOutcome, Int) {
        var skipped = 0
        let outcome = await performVersionedOperation(kind: .restore, operation: .restore, preview: preview) { session in
            let (events, continuation) = AsyncStream<(Int, Int)>.makeStream()
            async let worker = self.restoreFields(preview, selected: selected, session: session, continuation: continuation)
            for await (checked, total) in events {
                self.processingTask.update(checked: checked, total: total)
                progress(checked, total)
            }
            let result = await worker
            skipped = result.1
            return result.0
        }
        return (outcome, skipped)
    }

    @concurrent private func restoreFields(_ preview: ContactRestorePreview, selected: Set<String>, session: ContactVersionSession,
                                           continuation: AsyncStream<(Int, Int)>.Continuation) async -> (ContactOperationOutcome, Int) {
        defer { continuation.finish() }
        do {
            let skipped = try await versionStore.restore(preview, selected: selected, session: session,
                                                         shouldStop: { Task.isCancelled || !self.processing.withLock { $0 } },
                                                         progress: { continuation.yield(($0, $1)) })
            return (Task.isCancelled || !processing.withLock { $0 } ? .stopped : .completed, skipped)
        } catch { return (.failed((error as? ContactVersionError) ?? .saveFailed), 0) }
    }

    @MainActor private func processContactEvents(clearing: Bool, session: ContactVersionSession, task: ContactProcessingTask, resultHandler: @escaping ResultHandler) async -> ContactOperationOutcome {
        let (events, continuation) = AsyncStream<ProcessingEvent>.makeStream()
        var latestResult: String?
        // Consume one ordered stream so completion cannot overtake queued progress updates.
        async let worker = processContactStore(clearing: clearing, session: session, continuation: continuation)
        for await event in events {
            switch event {
            case .count(let count):
                contactsTotalCount = count
                task.update(checked: 0, total: count)
            case .visited(let checked, let total):
                task.update(checked: checked, total: total)
                // Publish once per checked contact, including skips, without losing the last result.
                handlingResult(resultHandler, result: latestResult, percentage: currentPercentage(checked, total: total))
            case .result(let result):
                latestResult = result
            }
        }
        return await worker
    }

    /// Contacts enumeration is synchronous; keep both counting and mutation off the main actor.
    @concurrent private func processContactStore(clearing: Bool, session: ContactVersionSession, continuation: AsyncStream<ProcessingEvent>.Continuation) async -> ContactOperationOutcome {
        defer { continuation.finish() }
        guard !Task.isCancelled, processing.withLock({ $0 }) else { return .stopped }
        let count = getContactsTotalCount
        continuation.yield(.count(count))
        guard !Task.isCancelled, processing.withLock({ $0 }) else { return .stopped }
        if clearing {
            return cleanContacts(count: count, session: session, continuation: continuation)
        }
        return executeContacts(count: count, session: session, continuation: continuation)
    }

    private func executeContacts(count: Int, session: ContactVersionSession, continuation: AsyncStream<ProcessingEvent>.Continuation) -> ContactOperationOutcome {
        var outcome = ContactOperationOutcome.completed
        var index = 1
        let whitelists = userDefaults.array(forKey: kWhitelistIdentifiersKey) as NSArray? ?? []
        do { try self.contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: self.keysToFetch as [CNKeyDescriptor]), usingBlock: { contact, stop in
            guard !Task.isCancelled, self.processing.withLock({ $0 }) else {
                stop.pointee = true
                outcome = .stopped
                return
            }
            let isWhitelist = whitelists.contains(contact.identifier)
            if !isWhitelist {
                let mutableContact: CNMutableContact = contact.mutableCopy() as! CNMutableContact
                // contact contains family name or given name
                if !contact.familyName.isEmpty || !contact.givenName.isEmpty {
                    var phoneticFamilyResult = ""
                    var phoneticGivenResult = ""
                    var phoneticFamilyBrief = ""
                    var phoneticGivenBrief = ""

                    // modify Contact
                    if let family = mutableContact.value(forKey: CNContactFamilyNameKey) as? String, let phoneticFamily = self.phonetic(family, needFix: self.fixPolyphonicCharacters) {
                        if self.shouldEnablePhoneticFirstAndLastName {
                            mutableContact.setValue(phoneticFamily.value, forKey: CNContactPhoneticFamilyNameKey)
                        }
                        phoneticFamilyResult = phoneticFamily.value
                        phoneticFamilyBrief = phoneticFamily.brief
                    }

                    if let given = mutableContact.value(forKey: CNContactGivenNameKey) as? String, let phoneticGiven = self.phonetic(given, needFix: false) {
                        if self.shouldEnablePhoneticFirstAndLastName {
                            mutableContact.setValue(phoneticGiven.value, forKey: CNContactPhoneticGivenNameKey)
                        }
                        phoneticGivenResult = phoneticGiven.value
                        phoneticGivenBrief = phoneticGiven.brief
                    }

                    self.addPhoneticNameForQuickSearchIfNeeded(mutableContact, familyBrief: phoneticFamilyBrief, givenBrief: phoneticGivenBrief)
                    do { try session.save(original: contact, modified: mutableContact) } catch { outcome = .failed((error as? ContactVersionError) ?? .saveFailed); stop.pointee = true; return }
                    let result = phoneticFamilyResult + " " + phoneticGivenResult
                    continuation.yield(.result(result))

                } else if self.massageCompanyKey, !contact.organizationName.isEmpty, mutableContact.isKeyAvailable(CNContactOrganizationNameKey), let company = mutableContact.value(forKey: CNContactOrganizationNameKey) as? String {
                    mutableContact.setValue(company, forKey: CNContactGivenNameKey)
                    if let phoneticCompany = self.phonetic(company, needFix: false) {
                        if self.shouldEnablePhoneticFirstAndLastName {
                            mutableContact.setValue(phoneticCompany.value, forKey: CNContactPhoneticGivenNameKey)
                        }
                        self.addPhoneticNameForQuickSearchIfNeeded(mutableContact, givenBrief: phoneticCompany.brief)
                        do { try session.save(original: contact, modified: mutableContact) } catch { outcome = .failed((error as? ContactVersionError) ?? .saveFailed); stop.pointee = true; return }
                        continuation.yield(.result(phoneticCompany.value))
                    }
                }
            }
            continuation.yield(.visited(checked: index, total: count))
            index += 1
        }) } catch { outcome = .failed(.saveFailed) }
        return outcome
    }

    private func cleanContacts(count: Int, session: ContactVersionSession, continuation: AsyncStream<ProcessingEvent>.Continuation) -> ContactOperationOutcome {
        var outcome = ContactOperationOutcome.completed
        var index = 1
        let whitelists = userDefaults.array(forKey: kWhitelistIdentifiersKey) as NSArray? ?? []
        do { try self.contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: self.keysToFetch as [CNKeyDescriptor]), usingBlock: { contact, stop in
            guard !Task.isCancelled, self.processing.withLock({ $0 }) else {
                stop.pointee = true
                outcome = .stopped
                return
            }
            let mutableContact: CNMutableContact = contact.mutableCopy() as! CNMutableContact
            let isWhitelist = whitelists.contains(contact.identifier)
            if !isWhitelist {
                // modify Contact
                // only clean who has Mandarin Latin.
                // Some english names may also have phonetic keys which you don't want to be cleaned.
                if let family = mutableContact.value(forKey: CNContactFamilyNameKey) as? String, self.antiPhonetic(family) {
                    mutableContact.setValue("", forKey: CNContactPhoneticFamilyNameKey)
                }
                if let given = mutableContact.value(forKey: CNContactGivenNameKey) as? String, self.antiPhonetic(given) {
                    mutableContact.setValue("", forKey: CNContactPhoneticGivenNameKey)
                }
                self.removePhoneticKeysIfNeeded(mutableContact)
                do { try session.save(original: contact, modified: mutableContact) } catch { outcome = .failed((error as? ContactVersionError) ?? .saveFailed); stop.pointee = true; return }
            }
            continuation.yield(.visited(checked: index, total: count))
            index += 1
        }) } catch { outcome = .failed(.saveFailed) }
        return outcome
    }

    var getContactsTotalCount: Int {
        // Match the processing request's unified results, rather than counting a unified
        // contact once per container when accounts contain linked contacts.
        let request = CNContactFetchRequest(keysToFetch: [CNContactIdentifierKey as CNKeyDescriptor])
        var count = 0
        try? contactStore.enumerateContacts(with: request) { _, stop in
            guard !Task.isCancelled, self.processing.withLock({ $0 }) else {
                stop.pointee = true
                return
            }
            count += 1
        }
        return count
    }

    @concurrent func fetchWhitelistContacts() async throws -> sending [CNContact] {
        try Task.checkCancellation()
        let request = CNContactFetchRequest(keysToFetch: keysToFetchForWhitelist)
        var fetched: [CNContact] = []
        try contactStore.enumerateContacts(with: request) { contact, stop in
            guard !Task.isCancelled else {
                stop.pointee = true
                return
            }
            fetched.append(contact)
        }
        try Task.checkCancellation()
        // Resolve names once, before sorting, and transfer only the immutable contacts to the UI.
        return fetched.map { (contact: $0, name: $0.whitelistDisplayName) }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
            .map { $0.contact }
    }

    @MainActor private func scheduleLocalNotification(body: String) {
        if let notificationHandler {
            notificationHandler(body)
            return
        }
        let notificationContent = UNMutableNotificationContent()
        notificationContent.sound = UNNotificationSound.default
        notificationContent.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("Scheduling notification failed: \(error.localizedDescription)")
            }
        }
    }

    @MainActor private func handlingCompletion(aborted: Bool, usedSystemTask: Bool) {
        isProcessing = false
        if applicationState() == .background, !aborted {
            logger.debug("Mission completed")
            if !usedSystemTask {
                scheduleLocalNotification(body: String(localized: "Your contacts have been updated."))
            }
            AppBadge.shared.setCount(0)
        }
    }

    @MainActor private func handlingResult(_ handle: ResultHandler, result: String?, percentage: Double) {
        switch applicationState() {
        case .active:
            handle(result, percentage)
        case .background:
            AppBadge.shared.setCount(Int(percentage))
            if percentage > 95 {
                handle(result, percentage)
            }
            let remainingTime = backgroundTimeRemaining()
            if remainingTime < 10, !processingTask.isUsingSystemTask, !didWarnAboutBackgroundTime {
                // Mark before submission; further progress or foreground/background changes must not repeat the warning.
                didWarnAboutBackgroundTime = true
                scheduleLocalNotification(body: String(localized: "Background time is running low. Open Phonetic to continue processing."))
            }
            logger.debug("Background time remaining \(remainingTime) seconds")
        default:
            break
        }
    }

    private func currentPercentage(_ index: Int, total: Int) -> Double {
        guard total > 0 else { return 100 }
        let percentage = Double(index) / Double(total) * 100
        return min(percentage, 100)
    }

    /**
     Checking whether there is any Mandarin Latin. If yes, return true, otherwise return false
     - parameter str: Source string
     - returns: is there any Mandarin Latin
     */
    func antiPhonetic(_ str: String) -> Bool {
        let str = str as NSString
        for i in 0 ..< str.length {
            let word = str.character(at: i)
            if word >= 0x4E00, word <= 0x9FFF {
                return true
            }
        }
        return false
    }

    /// only upcase the first word's first character
    private func upcaseInitial(_ str: String) -> String {
        let scalars = str.unicodeScalars
        let count = scalars.count
        guard count > 0 else { return str }
        let letters = CharacterSet.letters
        // check the first character is a letter or not
        guard !letters.contains(scalars.first!) else {
            return (str as NSString).substring(to: 1).uppercased() + (str as NSString).substring(from: 1)
        }
        var index = str.startIndex
        // be careful with emoji
        for (i, uni) in scalars.enumerated() {
            if letters.contains(uni) {
                if let _index = str.index(str.startIndex, offsetBy: i, limitedBy: str.endIndex) {
                    index = _index
                    break
                }
            }
        }
        var tempStr = str
        guard let nextIndex = str.index(index, offsetBy: 1, limitedBy: str.endIndex) else { return str }
        let range = Range(uncheckedBounds: (index, nextIndex))
        let uppercasedChar = str[range].uppercased()
        tempStr.replaceSubrange(range, with: uppercasedChar)
        return tempStr
    }

    private func briefInitial(_ array: [String]) -> String {
        guard !array.isEmpty else { return "" }
        var tempStr = ""
        for str in array {
            // remove "@", " "
            let _str = str.replacingOccurrences(of: "@", with: "").replacingOccurrences(of: " ", with: "")
            for s in _str.components(separatedBy: "-") {
                if !s.utf8.isEmpty {
                    tempStr += (s as NSString).substring(to: 1).uppercased()
                }
            }
        }
        if useTones {
            // remove tones
            let copy = tempStr.mutableCopy()
            CFStringTransform((copy as! CFMutableString), nil, kCFStringTransformStripCombiningMarks, false)
            return copy as! String
        }
        return tempStr
    }

    func phonetic(_ str: String, needFix: Bool) -> Phonetic? {
        let str = str.trimmingCharacters(in: .symbols) // remove all symblos e.g: ❤️
        var source = (needFix ? manaullyFixPolyphonicCharacters(str).mutableCopy() : str.mutableCopy()) as AnyObject
        let cfs = source as! CFMutableString
        CFStringTransform(cfs, nil, kCFStringTransformMandarinLatin, false)
        guard !(source as! String).isEqual(str) else { return nil }
        if !useTones {
            CFStringTransform(cfs, nil, kCFStringTransformStripCombiningMarks, false)
        }
        var brief: String
        if source.range(of: " ").location != NSNotFound {
            let phoneticParts = source.components(separatedBy: " ")
            brief = briefInitial(phoneticParts)
            source = NSMutableString(string: Phonetic.joinSyllables(phoneticParts, separated: separatePinyin, upcase: upcasePinyin))
        } else {
            brief = briefInitial([source as! String])
        }
        let value = upcaseInitial(source as! String)
        return Phonetic(brief: brief, value: value)
    }
}

// MARK: - Background Task
@MainActor
private extension PhoneticContacts {
    @objc func reinstateBackgroundTask() {
        if isProcessing, backgroundTask == .invalid, !processingTask.isUsingSystemTask {
            registerBackgroundTask()
        }
    }

    func registerBackgroundTask() {
        guard backgroundTask == .invalid else { return }
        let token = UUID()
        backgroundTaskToken = token
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            [weak self] in
            guard let self, self.backgroundTaskToken == token else { return }
            if !processingTask.isUsingSystemTask {
                self.isProcessing = false
            }
            self.endBackgroundTask()
        }
        if backgroundTask == .invalid {
            backgroundTaskToken = nil
        }
    }

    func endBackgroundTask() {
        backgroundTaskToken = nil
        guard backgroundTask != .invalid else { return }
        logger.debug("Background task ended")
        let identifier = backgroundTask
        backgroundTask = .invalid
        UIApplication.shared.endBackgroundTask(identifier)
    }
}

extension PhoneticContacts {
    var shouldEnablePhoneticFirstAndLastName: Bool {
        guard DetectPreferredLanguage.isChineseLanguage else { return true }
        return userDefaults.bool(forKey: kPhoneticFirstAndLastName, defaultValue: kPhoneticFirstAndLastNameDefaultBool)
    }

    private var upcasePinyin: Bool {
        return userDefaults.bool(forKey: kUpcasePinyin, defaultValue: kUpcasePinyinDefaultBool)
    }

    private var useTones: Bool {
        return userDefaults.bool(forKey: kUseTones, defaultValue: kUseTonesDefaultBool)
    }

    private var fixPolyphonicCharacters: Bool {
        return userDefaults.bool(forKey: kFixPolyphonicChar, defaultValue: kFixPolyphonicCharDefaultBool)
    }

    private var separatePinyin: Bool {
        return userDefaults.bool(forKey: kAlwaysSeparatePinyin, defaultValue: kAlwaysSeparatePinyinDefaultBool)
    }

    private var massageCompanyKey: Bool {
        return userDefaults.bool(forKey: kMassageCompanyKey, defaultValue: kMassageCompanyKeyDefaultBool)
    }
}
