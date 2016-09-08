//
//  PhoneticContacts.swift
//  Phonetic
//
//  Created by Augus on 1/28/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit
import Contacts


class PhoneticContacts {
    
    static let sharedInstance = PhoneticContacts()
    
    init() {
        DEBUGLog("Register UserNotificationSettings & UIApplicationDidBecomeActiveNotification")
        
        // register user notification settings
        UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
        
        NotificationCenter.default.addObserver(self, selector: #selector(PhoneticContacts.reinstateBackgroundTask), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    let contactStore = CNContactStore()
    let userDefaults = UserDefaults.standard
    
    var contactsTotalCount: Int = 0
    
    var keysToFetch: [String] {
        var keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneticGivenNameKey, CNContactPhoneticFamilyNameKey]
        
        if let CNContactQuickSearchKey = ContactKeyForQuickSearch {
            keys.append(CNContactQuickSearchKey)
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
    
    fileprivate var aborted = false

    fileprivate lazy var backgroundTask = UIBackgroundTaskInvalid
    
    fileprivate lazy var localNotification: UILocalNotification = {
        let localNotification = UILocalNotification()
        localNotification.soundName = UILocalNotificationDefaultSoundName
        return localNotification
    }()
    
    
    typealias ResultHandler = ((_ currentResult: String?, _ percentage: Double) -> Void)
    typealias AccessGrantedHandler = (() -> Void)
    typealias CompletionHandler = ((_ aborted: Bool) -> Void)
    
    func execute(_ handleAccessGranted: @escaping AccessGrantedHandler, resultHandler:  @escaping ResultHandler, completionHandler: @escaping CompletionHandler) {
        AppDelegate().requestContactsAccess { (accessGranted) in
            guard accessGranted else { return }
            
            // got the access...
            handleAccessGranted()
        }
        
        contactsTotalCount = getContactsTotalCount
        
        isProcessing = true
        aborted      = !isProcessing
        
        // uncomment the following line if you want to remove all Simulator's Contacts first.
        //        self.removeAllContactsOfSimulator()
        
        self.insertNewContactsForSimulatorIfNeeded(50)
//                self.insertNewContactsForDevice(100)
        
        
        GlobalBackgroundQueue.async {
            
            var index = 1
            let count = self.contactsTotalCount
            
            do {
                try self.contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: self.keysToFetch as [CNKeyDescriptor]), usingBlock: { (contact, _) -> Void in
                    
                    guard self.isProcessing else {
                        self.aborted = true
                        return
                    }
                    
                    if !contact.familyName.isEmpty || !contact.givenName.isEmpty {
                        let mutableContact: CNMutableContact = contact.mutableCopy() as! CNMutableContact
                        
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
                        
                        index += 1
                    }
                })
            } catch {
                
                DEBUGLog("fetching Contacts failed ! - \(error)")
            }
            
            self.isProcessing = false
            
            self.handlingCompletion(completionHandler)
        }
        
    }
    
    func cleanMandarinLatinPhonetic(_ handleAccessGranted: @escaping AccessGrantedHandler, resultHandler: @escaping ResultHandler, completionHandler: @escaping CompletionHandler) {
        AppDelegate().requestContactsAccess { (accessGranted) in
            guard accessGranted else { return }
            
            // got the access...
            handleAccessGranted()
        }
        
        contactsTotalCount = getContactsTotalCount
        
        isProcessing = true
        aborted = !isProcessing
        
        GlobalBackgroundQueue.async {
            
            var index = 1
            let count = self.contactsTotalCount
            
            do {
                try self.contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: self.keysToFetch as [CNKeyDescriptor]), usingBlock: { (contact, _) -> Void in
                    
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
            } catch {
                
                DEBUGLog("fetching Contacts failed ! - \(error)")
            }
            
            self.isProcessing = false
            
            self.handlingCompletion(completionHandler)
        }
    }
    
    var getContactsTotalCount: Int {
        let contacts = fetchAllContacts(keysToFetch: [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor])
        return contacts.count
    }
    
    fileprivate func fetchAllContacts(keysToFetch keys: [CNKeyDescriptor]) -> [CNContact] {
        
        AppDelegate().requestContactsAccess { (accessGranted) in
            guard accessGranted else { return }
        }
        
        let containers = (try? contactStore.containers(matching: nil)) ?? []
        
        let contacts = containers.flatMap { (container) -> [CNContact] in
            let predicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            return (try? contactStore.unifiedContacts(matching: predicate, keysToFetch: keys)) ?? []
        }
        
        return contacts
    }
    
    fileprivate func handlingCompletion(_ handle: @escaping CompletionHandler) {
        
        switch UIApplication.shared.applicationState {
        case .background:
            // completed not aborted
            if !aborted {
                DEBUGLog("Mission Completed")
                
                localNotification.fireDate = Date()
                localNotification.alertBody = NSLocalizedString("Mission Completed !", comment: "Local Notification - alert body")
                UIApplication.shared.scheduleLocalNotification(localNotification)
            }
        default:
            break
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            handle(self.aborted)
        })
    }
    
    fileprivate func handlingResult(_ handle: @escaping ResultHandler, result: String?, index: Int, total: Int) {
        
        let percentage = currentPercentage(index, total: total)
        
        switch UIApplication.shared.applicationState {
        case .active:
            DispatchQueue.main.async(execute: { () -> Void in
                handle(result, percentage)
            })
            
        case .background:
            
            // set icon badge number as current percentage.
            UIApplication.shared.applicationIconBadgeNumber = Int(percentage)
            
            // handling results while it is almost complete to correct the UI of percentage.
            if percentage > 95 {
                DispatchQueue.main.async(execute: { () -> Void in
                    handle(result, percentage)
                })
            }
            
            let remainingTime = UIApplication.shared.backgroundTimeRemaining
            
            // App is about to be terminated, send notification.
            if remainingTime < 10 {
                localNotification.fireDate = Date()
                localNotification.alertBody = NSLocalizedString("Phonetic is about to be terminated! Please open it again to complete the mission.", comment: "Local Notification - App terminated notification")
                UIApplication.shared.scheduleLocalNotification(localNotification)
            }
            
            DEBUGLog("Background time remaining \(remainingTime) seconds")
            
        default: break
        }
        
    }
    
    fileprivate func saveContact(_ contact: CNMutableContact) {
        let saveRequest = CNSaveRequest()
        saveRequest.update(contact)
        do {
            try self.contactStore.execute(saveRequest)
        } catch {
            
            DEBUGLog("saving Contact failed ! - \(error)")
        }
    }
    
    fileprivate func currentPercentage(_ index: Int, total: Int) -> Double {
        let percentage = Double(index) / Double(total) * 100
        return min(percentage, 100)
    }
    
    
    /**
     Checking whether there is any Mandarin Latin. If yes, return true, otherwise return false
     
     - parameter str: Source string
     
     - returns: is there any Mandarin Latin
     */
    fileprivate func antiPhonetic(_ str: String) -> Bool {
        let str = str as NSString
        for i in 0..<str.length {
            let word = str.character(at: i)
            if word >= 0x4e00 && word <= 0x9fff {
                return true
            }
        }
        return false
    }
    
    fileprivate func upcaseInitial(_ str: String) -> String {
        var tempStr = str
        if str.utf8.count > 0 {
            tempStr = (str as NSString).substring(to: 1).uppercased() + (str as NSString).substring(from: 1)
        }
        return tempStr
    }
    
    fileprivate func briefInitial(_ array: [String]) -> String {
        guard array.count > 0 else { return "" }
        
        var tempStr = ""
        for str in array {
            if str.utf8.count > 0 {
                tempStr += (str as NSString).substring(to: 1).uppercased()
            }
        }
        
        if useTones {
            // remove tones
            let copy = (tempStr as NSString).mutableCopy()
            CFStringTransform(copy as! CFMutableString, nil, kCFStringTransformStripCombiningMarks, false)
            return copy as! String
        }
        
        return tempStr
    }
    
    fileprivate func phonetic(_ str: String, needFix: Bool) -> Phonetic? {
        var source = (needFix ? manaullyFixPolyphonicCharacters(str).mutableCopy() : str.mutableCopy()) as AnyObject
        
        CFStringTransform(source as! CFMutableString, nil, kCFStringTransformMandarinLatin, false)
        CFStringTransform(source as! CFMutableString, nil, kCFStringTransformStripCombiningMarks, useTones)
        
        var brief: String
        
        if !(source as! NSString).isEqual(to: str) {
            if (source as AnyObject).range(of: " ").location != NSNotFound {
                let phoneticParts = (source as AnyObject).components(separatedBy: " ")
                source = NSMutableString()
                brief = briefInitial(phoneticParts)
                
                if separatePinyin {
                    for part in phoneticParts {
                        // upcase all words
                        source.append(upcaseInitial(part))
                        
                        // insert blank space
                        source.append(" ")
                    }
                    
                } else {
                    if upcasePinyin {
                        
                        // upcase all words of First Name.   e.g:  Liu YiFei
                        for part in phoneticParts {
                            source.append(upcaseInitial(part))
                        }
                        
                    } else {
                        
                        // only upcase the first word of First Name.    e.g: Liu Yifei
                        for (index, part) in phoneticParts.enumerated() {
                            if index == 0 {
                                source.append(upcaseInitial(part))
                            } else {
                                source.append(part)
                            }
                        }
                    }
                }
                
            } else {
                brief = briefInitial([source as! String])
            }
            
            let value = upcaseInitial(source as! String)//.stringByReplacingOccurrencesOfString(" ", withString: "")
            return Phonetic(brief: brief, value: value)
        }
        return nil
    }
    
}


// MARK: - Background Task

fileprivate extension PhoneticContacts {
    
    @objc func reinstateBackgroundTask() {
        if isProcessing && (backgroundTask == UIBackgroundTaskInvalid) {
            registerBackgroundTask()
        }
    }
    
    func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            [unowned self] in
            self.endBackgroundTask()
        }
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }
    
    func endBackgroundTask() {
        DEBUGLog("Background task ended.")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }
}


extension PhoneticContacts {
    
    internal var shouldEnablePhoneticFirstAndLastName: Bool {
        
        guard DetectPreferredLanguage.isChineseLanguage else { return true }
        
        return userDefaults.bool(forKey: kPhoneticFirstAndLastName, defaultValue: kPhoneticFirstAndLastNameDefaultBool)
    }
    
    fileprivate var upcasePinyin: Bool {
        return userDefaults.bool(forKey: kUpcasePinyin, defaultValue: kUpcasePinyinDefaultBool)
    }
    
    fileprivate var useTones: Bool {
        return userDefaults.bool(forKey: kUseTones, defaultValue: kUseTonesDefaultBool)
    }
    
    fileprivate var fixPolyphonicCharacters: Bool {
        return userDefaults.bool(forKey: kFixPolyphonicChar, defaultValue: kFixPolyphonicCharDefaultBool)
    }
    
    fileprivate var separatePinyin: Bool {
        return userDefaults.bool(forKey: kAlwaysSeparatePinyin, defaultValue: kAlwaysSeparatePinyinDefaultBool)
    }
    
}

