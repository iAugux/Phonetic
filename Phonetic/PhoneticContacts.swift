//
//  PhoneticContacts.swift
//  Phonetic
//
//  Created by Augus on 1/28/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit
import Contacts

final class PhoneticContacts {
    static let shared = PhoneticContacts()

    private init() {
        asLog("Register Notifications")
        // register user notification settings
        GlobalMainQueue.async {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
        }
        NotificationCenter.default.addObserver(self, selector: #selector(reinstateBackgroundTask), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    let contactStore = CNContactStore()
    let userDefaults = UserDefaults.standard
    var contactsTotalCount: Int = 0
    var keysToFetch: [String] {
        var keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneticGivenNameKey, CNContactPhoneticFamilyNameKey, CNContactOrganizationNameKey]
        if let quickSearchKey = ContactKeyForQuickSearch {
            keys.append(quickSearchKey)
        }
        keys.append(contentsOf: keysToFetchIfNeeded)
        return keys
    }

    var isProcessing = false {
        didSet {
            if isProcessing {
                registerBackgroundTask()
            } else {
                endBackgroundTask()
            }
        }
    }

    private var aborted = false
    private lazy var backgroundTask = UIBackgroundTaskIdentifier.invalid
    private lazy var localNotification: UILocalNotification = {
        let localNotification = UILocalNotification()
        localNotification.soundName = UILocalNotificationDefaultSoundName
        return localNotification
    }()

    typealias ResultHandler = ((_ currentResult: String?, _ percentage: Double) -> Void)
    func execute(resultHandler: @escaping ResultHandler, completionHandler: @escaping BoolClosure) {
        contactsTotalCount = getContactsTotalCount
        isProcessing = true
        aborted = !isProcessing

        // uncomment the following line if you want to remove all Simulator's Contacts first.
        // self.removeAllContactsOfSimulator()

        // self.insertNewContactsForSimulatorIfNeeded(50)
        // self.insertNewContactsForDevice(100)

        GlobalBackgroundQueue.async {
            var index = 1
            let count = self.contactsTotalCount
            _ = try? self.contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: self.keysToFetch as [CNKeyDescriptor]), usingBlock: { contact, _ -> Void in
                guard self.isProcessing else {
                    self.aborted = true
                    return
                }
                let mutableContact: CNMutableContact = contact.mutableCopy() as! CNMutableContact
                // contact contains family name or given name
                if !contact.familyName.isEmpty || !contact.givenName.isEmpty {
                    var phoneticFamilyResult = ""
                    var phoneticGivenResult  = ""
                    var phoneticFamilyBrief  = ""
                    var phoneticGivenBrief   = ""

                    // modify Contact
                    if let family = mutableContact.value(forKey: CNContactFamilyNameKey) as? String {
                        if let phoneticFamily = self.phonetic(family, needFix: self.fixPolyphonicCharacters) {
                            if self.shouldEnablePhoneticFirstAndLastName {
                                mutableContact.setValue(phoneticFamily.value, forKey: CNContactPhoneticFamilyNameKey)
                            }
                            phoneticFamilyResult = phoneticFamily.value
                            phoneticFamilyBrief  = phoneticFamily.brief
                        }
                    }

                    if let given = mutableContact.value(forKey: CNContactGivenNameKey) as? String {
                        if let phoneticGiven = self.phonetic(given, needFix: false) {
                            if self.shouldEnablePhoneticFirstAndLastName {
                                mutableContact.setValue(phoneticGiven.value, forKey: CNContactPhoneticGivenNameKey)
                            }
                            phoneticGivenResult = phoneticGiven.value
                            phoneticGivenBrief  = phoneticGiven.brief
                        }
                    }

                    self.addPhoneticNameForQuickSearchIfNeeded(mutableContact, familyBrief: phoneticFamilyBrief, givenBrief: phoneticGivenBrief)
                    self.saveContact(mutableContact)
                    let result = phoneticFamilyResult + " " + phoneticGivenResult
                    self.handlingResult(resultHandler, result: result, index: index, total: count)

                } else if self.massageCompanyKey && !contact.organizationName.isEmpty {
                    if mutableContact.isKeyAvailable(CNContactOrganizationNameKey) {
                        if let company = mutableContact.value(forKey: CNContactOrganizationNameKey) as? String {
                            mutableContact.setValue(company, forKey: CNContactGivenNameKey)
                            if let phoneticCompany = self.phonetic(company, needFix: false) {
                                if self.shouldEnablePhoneticFirstAndLastName {
                                    mutableContact.setValue(phoneticCompany.value, forKey: CNContactPhoneticGivenNameKey)
                                }
                                self.addPhoneticNameForQuickSearchIfNeeded(mutableContact, givenBrief: phoneticCompany.brief)
                                self.saveContact(mutableContact)
                            }
                        }
                    }
                }
                index += 1
            })
            self.isProcessing = false
            self.handlingCompletion(completionHandler)
        }
    }

    func cleanMandarinLatinPhonetic(resultHandler: @escaping ResultHandler, completionHandler: @escaping BoolClosure) {
        contactsTotalCount = getContactsTotalCount
        isProcessing = true
        aborted = !isProcessing
        GlobalBackgroundQueue.async {
            var index = 1
            let count = self.contactsTotalCount
            _ = try? self.contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: self.keysToFetch as [CNKeyDescriptor]), usingBlock: { contact, _ -> Void in
                guard self.isProcessing else {
                    self.aborted = true
                    return
                }
                let mutableContact: CNMutableContact = contact.mutableCopy() as! CNMutableContact
                // modify Contact
                /// only clean who has Mandarin Latin.
                /// Some english names may also have phonetic keys which you don't want to be cleaned.
                if let family = mutableContact.value(forKey: CNContactFamilyNameKey) as? String {
                    if self.antiPhonetic(family) {
                        mutableContact.setValue("", forKey: CNContactPhoneticFamilyNameKey)
                    }
                }
                if let given = mutableContact.value(forKey: CNContactGivenNameKey) as? String {
                    if self.antiPhonetic(given) {
                        mutableContact.setValue("", forKey: CNContactPhoneticGivenNameKey)
                    }
                }
                self.removePhoneticKeysIfNeeded(mutableContact)
                self.saveContact(mutableContact)
                self.handlingResult(resultHandler, result: nil, index: index, total: count)
                index += 1
            })
            self.isProcessing = false
            self.handlingCompletion(completionHandler)
        }
    }

    var getContactsTotalCount: Int {
        let contacts = fetchAllContacts(keysToFetch: [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor])
        return contacts.count
    }

    func fetchAllContacts(keysToFetch keys: [CNKeyDescriptor]) -> [CNContact] {
        let containers = (try? contactStore.containers(matching: nil)) ?? []
        let contacts = containers.flatMap { (container) -> [CNContact] in
            let predicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            return (try? contactStore.unifiedContacts(matching: predicate, keysToFetch: keys)) ?? []
        }
        return contacts
    }

    func fetchContactWithIdentifiers(_ identifiers: [String], keysToFetch: [CNKeyDescriptor]) -> [CNContact]? {
        let predicate = CNContact.predicateForContacts(withIdentifiers: identifiers)
        return try? contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
    }

    private func handlingCompletion(_ handle: @escaping BoolClosure) {
        GlobalMainQueue.async { [weak self] in
            guard let ss = self else { return }
            switch UIApplication.shared.applicationState {
            case .background:
                // completed not aborted
                if !ss.aborted {
                    asLog("Mission Completed")
                    ss.localNotification.fireDate = Date()
                    ss.localNotification.alertBody = NSLocalizedString("Mission Completed !", comment: "Local Notification - alert body")
                    UIApplication.shared.scheduleLocalNotification(ss.localNotification)
                    // reset icon badge number to zero for OCD
                    UIApplication.shared.applicationIconBadgeNumber = 0
                }
            default:
                break
            }
            DispatchQueue.main.async(execute: {
                handle(ss.aborted)
            })
        }
    }

    private func handlingResult(_ handle: @escaping ResultHandler, result: String?, index: Int, total: Int) {
        let percentage = currentPercentage(index, total: total)
        GlobalMainQueue.async { [weak self] in
            guard let ss = self else { return }
            switch UIApplication.shared.applicationState {
            case .active:
                DispatchQueue.main.async(execute: {
                    handle(result, percentage)
                })
            case .background:
                // set icon badge number as current percentage.
                UIApplication.shared.applicationIconBadgeNumber = Int(percentage)
                // handling results while it is almost completing to correct the UI of percentage.
                if percentage > 95 {
                    DispatchQueue.main.async(execute: {
                        handle(result, percentage)
                    })
                }
                let remainingTime = UIApplication.shared.backgroundTimeRemaining
                // App is about to be terminated, send notification.
                if remainingTime < 10 {
                    ss.localNotification.fireDate = Date()
                    ss.localNotification.alertBody = NSLocalizedString("Phonetic is about to be terminated! Please open it again to complete the mission.", comment: "Local Notification - App terminated notification")
                    UIApplication.shared.scheduleLocalNotification(ss.localNotification)
                }
                asLog("Background time remaining \(remainingTime) seconds")
            default: break
            }
        }
    }

    func saveContact(_ contact: CNMutableContact) {
        let saveRequest = CNSaveRequest()
        saveRequest.update(contact)
        do {
            try self.contactStore.execute(saveRequest)
        } catch {
            asLog("saving Contact failed ! - \(error)")
        }
    }

    private func currentPercentage(_ index: Int, total: Int) -> Double {
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
        for i in 0..<str.length {
            let word = str.character(at: i)
            if word >= 0x4e00 && word <= 0x9fff {
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
        guard array.count > 0 else { return "" }
        var tempStr = ""
        for str in array {
            // remove "@", " "
            let _str = str.replacingOccurrences(of: ["@", " "], with: "")
            for s in _str.components(separatedBy: "-") {
                if s.utf8.count > 0 {
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

    private func phonetic(_ str: String, needFix: Bool) -> Phonetic? {
        let str = str.trimmingCharacters(in: .symbols) // remove all symblos e.g: ❤️
        var source = (needFix ? manaullyFixPolyphonicCharacters(str).mutableCopy() : str.mutableCopy()) as AnyObject
        let cfs = source as! CFMutableString
        CFStringTransform(cfs, nil, kCFStringTransformMandarinLatin, false)
        CFStringTransform(cfs, nil, kCFStringTransformStripCombiningMarks, useTones)
        var brief: String
        guard !(source as! String).isEqual(str) else { return nil }
        if source.range(of: " ").location != NSNotFound {
            let phoneticParts = source.components(separatedBy: " ")
            source = NSMutableString()
            brief = briefInitial(phoneticParts)
            if separatePinyin {
                // upcase all words
                for part in phoneticParts {
                    source.append(part.capitalized)
                    source.append(" ") // insert blank space
                }
            } else {
                if upcasePinyin {
                    // upcase all words of First Name.   e.g: Liu YiFei
                    for part in phoneticParts {
                        source.append(part.capitalized)
                    }
                } else {
                    // only upcase the first word of First Name.   e.g: Liu Yifei
                    for (index, part) in phoneticParts.enumerated() {
                        if index == 0 {
                            source.append(part.capitalized)
                        } else {
                            source.append(part)
                        }
                    }
                }
            }
        } else {
            brief = briefInitial([source as! String])
        }
        let value = upcaseInitial(source as! String)
        return Phonetic(brief: brief, value: value)
    }

    func phonetic(_ str: String) -> String {
        let source = str.mutableCopy()
        let cfs = source as! CFMutableString
        CFStringTransform(cfs, nil, kCFStringTransformMandarinLatin, false)
        CFStringTransform(cfs, nil, kCFStringTransformStripCombiningMarks, useTones)
        return source as! String
    }
}

// MARK: - Background Task
private extension PhoneticContacts {
    @objc func reinstateBackgroundTask() {
        if isProcessing && (backgroundTask == .invalid) {
            registerBackgroundTask()
        }
    }

    func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            [unowned self] in
            self.endBackgroundTask()
        }
        assert(backgroundTask != .invalid)
    }

    func endBackgroundTask() {
        asLog("Background task ended.")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
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
