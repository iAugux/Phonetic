//
//  PhoneticContacts.swift
//  Phonetic
//
//  Created by Augus on 1/28/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation
import Contacts


class PhoneticContacts {
    
    static let sharedInstance = PhoneticContacts()
    
    let contactStore = CNContactStore()
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    var isProcessing    = false
    private var aborted = false
    
    var keysToFetch: [String] {
        var keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneticGivenNameKey, CNContactPhoneticFamilyNameKey]
        
        if let CNContactQuickSearchKey = ContactKeyForQuickSearch {
            keys.append(CNContactQuickSearchKey)
        }
        
        keys.appendContentsOf(keysToFetchIfNeeded)
        
        return keys
    }
    
    typealias ResultHandler = ((currentResult: String?, percentage: Int) -> Void)
    typealias AccessGrantedHandler = (() -> Void)
    typealias CompletionHandler = ((aborted: Bool) -> Void)
    
    func execute(handleAccessGranted: AccessGrantedHandler, handleResult:  ResultHandler, completionHandler: CompletionHandler) {
        AppDelegate().requestContactsAccess { (accessGranted) in
            guard accessGranted else { return }
            
            // got the access...
            handleAccessGranted()
        }
        
        isProcessing = true
        aborted      = !isProcessing
        
        // uncomment the following line if you want to remove all Simulator's Contacts first.
//        self.removeAllContactsOfSimulator()
        
//        self.insertNewContactsForSimulatorIfNeeded(50)
//        self.insertNewContactsForDevice(100)
        
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.rawValue), 0)) {
            
            var index = 1
            let count = self.contactsTotalCount()
            
            do {
                try self.contactStore.enumerateContactsWithFetchRequest(CNContactFetchRequest(keysToFetch: self.keysToFetch), usingBlock: { (contact, _) -> Void in
                    
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
                        if let family = mutableContact.valueForKey(CNContactFamilyNameKey) as? String {
                            if let phoneticFamily = self.phonetic(family, needFix: self.fixPolyphonicCharacters) {
                                
                                if self.shouldEnablePhoneticFirstAndLastName {
                                    mutableContact.setValue(phoneticFamily.value, forKey: CNContactPhoneticFamilyNameKey)
                                }
                                
                                phoneticFamilyResult = phoneticFamily.value
                                phoneticFamilyBrief  = phoneticFamily.brief
                            }
                        }
                        
                        if let given = mutableContact.valueForKey(CNContactGivenNameKey) as? String {
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
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            handleResult(currentResult: result, percentage: self.currentPercentage(index, total: count))
                        })
                        
                        index += 1
                    }
                })
            } catch {
                #if DEBUG
                    NSLog("fetching Contacts failed ! - \(error)")
                #endif
            }
            
            self.isProcessing = false
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionHandler(aborted: self.aborted)
            })
        }
        
    }
    
    func clearMandarinLatinPhonetic(handleAccessGranted: AccessGrantedHandler, handleResult: ResultHandler, completionHandler: CompletionHandler) {
        AppDelegate().requestContactsAccess { (accessGranted) in
            guard accessGranted else { return }
            
            // got the access...
            handleAccessGranted()
        }
        
        isProcessing = true
        aborted = !isProcessing
        
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.rawValue), 0)) {
            
            var index = 1
            let count = self.contactsTotalCount()
            
            do {
                try self.contactStore.enumerateContactsWithFetchRequest(CNContactFetchRequest(keysToFetch: self.keysToFetch), usingBlock: { (contact, _) -> Void in
                    
                    guard self.isProcessing else {
                        self.aborted = true
                        return
                    }
                    
                    let mutableContact: CNMutableContact = contact.mutableCopy() as! CNMutableContact
                    
                    // modify Contact
                    /// only clear who has Mandarin Latin.
                    /// Some english names may also have phonetic keys which you don't want to be cleared.
                    if let family = mutableContact.valueForKey(CNContactFamilyNameKey) as? String {
                        if self.antiPhonetic(family) {
                            mutableContact.setValue("", forKey: CNContactPhoneticFamilyNameKey)
                        }
                    }
                    
                    if let given = mutableContact.valueForKey(CNContactGivenNameKey) as? String {
                        if self.antiPhonetic(given) {
                            mutableContact.setValue("", forKey: CNContactPhoneticGivenNameKey)
                        }
                    }
                    
                    self.removePhoneticKeysIfNeeded(mutableContact)
                    
                    self.saveContact(mutableContact)
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        handleResult(currentResult: nil, percentage: self.currentPercentage(index, total: count))
                    })
                    
                    index += 1
                })
            } catch {
                #if DEBUG
                    NSLog("fetching Contacts failed ! - \(error)")
                #endif
            }
            
            self.isProcessing = false
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionHandler(aborted: self.aborted)
            })
        }
    }
    
    func contactsTotalCount() -> Int {
        let predicate = CNContact.predicateForContactsInContainerWithIdentifier(contactStore.defaultContainerIdentifier())
        
        do {
            let contacts = try self.contactStore.unifiedContactsMatchingPredicate(predicate, keysToFetch: [CNContactGivenNameKey, CNContactFamilyNameKey])
            return contacts.count
        } catch {
            #if DEBUG
                NSLog("\(error)")
            #endif
            return 0
        }
    }
    
    private func saveContact(contact: CNMutableContact) {
        let saveRequest = CNSaveRequest()
        saveRequest.updateContact(contact)
        do {
            try self.contactStore.executeSaveRequest(saveRequest)
        } catch {
            #if DEBUG
                NSLog("saving Contact failed ! - \(error)")
            #endif
        }
    }
    
    private func currentPercentage(index: Int, total: Int) -> Int {
        return min(100 * index / total, 100)
    }
    
    
    /**
     Checking whether there is any Mandarin Latin. If yes, return true, otherwise return false
     
     - parameter str: Source string
     
     - returns: is there any Mandarin Latin
     */
    private func antiPhonetic(str: String) -> Bool {
        let str = str as NSString
        for i in 0..<str.length {
            let word = str.characterAtIndex(i)
            if word >= 0x4e00 && word <= 0x9fff {
                return true
            }
        }
        return false
    }
    
    private func upcaseInitial(str: String) -> String {
        var tempStr = str
        if str.utf8.count > 0 {
            tempStr = (str as NSString).substringToIndex(1).uppercaseString.stringByAppendingString((str as NSString).substringFromIndex(1))
        }
        return tempStr
    }
    
    private func briefInitial(array: [String]) -> String {
        guard array.count > 0 else { return "" }
        
        var tempStr = ""
        for str in array {
            if str.utf8.count > 0 {
                tempStr += (str as NSString).substringToIndex(1).uppercaseString
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
    
    private func phonetic(str: String, needFix: Bool) -> Phonetic? {
        var source = needFix ? manaullyFixPolyphonicCharacters(str).mutableCopy() : str.mutableCopy()
        
        CFStringTransform(source as! CFMutableStringRef, nil, kCFStringTransformMandarinLatin, false)
        CFStringTransform(source as! CFMutableStringRef, nil, kCFStringTransformStripCombiningMarks, useTones)
        
        var brief: String
        
        if !(source as! NSString).isEqualToString(str) {
            if source.rangeOfString(" ").location != NSNotFound {
                let phoneticParts = source.componentsSeparatedByString(" ")
                source = NSMutableString()
                brief = briefInitial(phoneticParts)
                
                if upcasePinyin {
                    
                    // upcase all words of First Name.   e.g:  Liu YiFei
                    for part in phoneticParts {
                        source.appendString(upcaseInitial(part))
                    }
                    
                } else {
                    
                    // only upcase the first word of First Name.    e.g: Liu Yifei
                    for (index, part) in phoneticParts.enumerate() {
                        if index == 0 {
                            source.appendString(upcaseInitial(part))
                        } else {
                            source.appendString(part)
                        }
                    }
                }
                
            } else {
                brief = briefInitial([source as! String])
            }
            
            let value = upcaseInitial(source as! String).stringByReplacingOccurrencesOfString(" ", withString: "")
            return Phonetic(brief: brief, value: value)
        }
        return nil
    }
    
    private func manaullyFixPolyphonicCharacters(str: String) -> String {

        var tempString = str
        let specialCharacters = PolyphonicCharacters.SpecialCharacters
        let newCharacters     = PolyphonicCharacters.NewCharacters
        
        for (index, element) in specialCharacters.enumerate() {
            if tempString.containsString(element) {
                tempString = tempString.stringByReplacingOccurrencesOfString(element, withString: newCharacters[index])
            }
        }
        return tempString
    }
    
}

extension PhoneticContacts {
    
    internal var shouldEnablePhoneticFirstAndLastName: Bool {
        
        guard DetectPreferredLanguage.isChineseLanguage else { return true }
        
        return userDefaults.getBool(kPhoneticFirstAndLastName, defaultKeyValue: kPhoneticFirstAndLastNameDefaultBool)
    }
    
    private var upcasePinyin: Bool {
        return userDefaults.getBool(kUpcasePinyin, defaultKeyValue: kUpcasePinyinDefaultBool)
    }
    
    private var useTones: Bool {
        return userDefaults.getBool(kUseTones, defaultKeyValue: kUseTonesDefaultBool)
    }
    
    private var fixPolyphonicCharacters: Bool {
        return userDefaults.getBool(kFixPolyphonicChar, defaultKeyValue: kFixPolyphonicCharDefaultBool)
    }
    
    
    
}

