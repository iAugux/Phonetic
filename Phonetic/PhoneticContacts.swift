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
    let keysForFetching = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneticGivenNameKey, CNContactPhoneticFamilyNameKey]
    
    typealias ResultHandler = ((currentResult: String?, percentage: Int) -> Void)
    
    func execute(handleAccessGranted: (() -> Void), handleResult:  ResultHandler, completionHandler: (() -> Void)) {
        AppDelegate().requestContactsAccess { (accessGranted) in
            guard accessGranted else { return }
            
            // got the access...
            handleAccessGranted()
        }
        
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.rawValue), 0)) {
            
            var index = 1
            let count = self.contactsTotalCount()
            
            do {
                try self.contactStore.enumerateContactsWithFetchRequest(CNContactFetchRequest(keysToFetch: self.keysForFetching), usingBlock: { (contact, _) -> Void in
                    if !contact.familyName.isEmpty || !contact.givenName.isEmpty {
                        let mutableContact = contact.mutableCopy() as! CNMutableContact
                        
                        var phoneticFamilyResult = ""
                        var phoneticGivenResult  = ""
                        
                        // modify Contact
                        if let family = mutableContact.valueForKey(CNContactFamilyNameKey) as? String {
                            if let phoneticFamily = self.phonetic(family, needFix: true) {
                                mutableContact.setValue(phoneticFamily, forKey: CNContactPhoneticFamilyNameKey)
                                phoneticFamilyResult = phoneticFamily
                            }
                        }
                        if let given = mutableContact.valueForKey(CNContactGivenNameKey) as? String {
                            if let phoneticGiven = self.phonetic(given, needFix: false) {
                                mutableContact.setValue(phoneticGiven, forKey: CNContactPhoneticGivenNameKey)
                                phoneticGivenResult = phoneticGiven
                            }
                        }
                        
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
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionHandler()
            })
        }
        
    }
    
    func clearMandarinLatinPhonetic(handleAccessGranted: (() -> Void), handleResult: ResultHandler, completionHandler: (() -> Void)) {
        AppDelegate().requestContactsAccess { (accessGranted) in
            guard accessGranted else { return }
            
            // got the access...
            handleAccessGranted()
        }
        
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.rawValue), 0)) {
            
            var index = 1
            let count = self.contactsTotalCount()
            
            do {
                try self.contactStore.enumerateContactsWithFetchRequest(CNContactFetchRequest(keysToFetch: self.keysForFetching), usingBlock: { (contact, _) -> Void in
                    let mutableContact = contact.mutableCopy() as! CNMutableContact
                    
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
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionHandler()
            })
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
    
    private func contactsTotalCount() -> Int {
        let predicate = CNContact.predicateForContactsInContainerWithIdentifier(contactStore.defaultContainerIdentifier())
        
        do {
            let contacts = try self.contactStore.unifiedContactsMatchingPredicate(predicate, keysToFetch: keysForFetching)
            return contacts.count
        } catch {
            #if DEBUG
                NSLog("\(error)")
            #endif
            return 0
        }
    }
    
    /**
     Checking whether there is any Mandarin Latin. If yes, return true, otherwise return false
     
     - parameter str: Source string
     
     - returns: is there any Mandarin Latin
     */
    private func antiPhonetic(str: String) -> Bool {
        for i in 0..<str.utf8.count {
            let word = (str as NSString).characterAtIndex(i)
            if word > 0x4e00 && word < 0x9fff {
                return true
            }
        }
        return false
    }
    
    private func upcaseInitial(str: String) -> String {
        var newStr = str
        if str.utf8.count > 0 {
            newStr = (str as NSString).substringToIndex(1).uppercaseString.stringByAppendingString((str as NSString).substringFromIndex(1))
        }
        return newStr
    }
    
    private func phonetic(str: String, needFix: Bool) -> String? {
        var source = needFix ? manaullyFixPolyphonicCharacters(str).mutableCopy() : str.mutableCopy()
        
        CFStringTransform(source as! CFMutableStringRef, nil, kCFStringTransformMandarinLatin, false)
        
        /// adding accents or not
        if userDefaults.valueForKey(kAddAccent) == nil {
            userDefaults.setBool(kAddAccentDefaultBool, forKey: kAddAccent)
            userDefaults.synchronize()
        }
        
        if !userDefaults.boolForKey(kAddAccent) {
            CFStringTransform(source as! CFMutableStringRef, nil, kCFStringTransformStripCombiningMarks, false)
        }
        
        if !(source as! NSString).isEqualToString(str) {
            if source.rangeOfString(" ").location != NSNotFound {
                let phoneticParts = source.componentsSeparatedByString(" ")
                source = NSMutableString()
                for part in phoneticParts {
                    source.appendString(upcaseInitial(part))
                }
            }
            return upcaseInitial(source as! String).stringByReplacingOccurrencesOfString(" ", withString: "")
        }
        return nil
    }
    
    private func manaullyFixPolyphonicCharacters(str: String) -> String {
        
        /// fixing polyphonic character or not
        if userDefaults.valueForKey(kFixPolyphonicChar) == nil {
            userDefaults.setBool(kFixPolyphonicCharDefaultBool, forKey: kFixPolyphonicChar)
            userDefaults.synchronize()
        }
        
        if !userDefaults.boolForKey(kFixPolyphonicChar) {
            return str
        }
        
        var tempString = str
        let specialCharacters = ["沈", "单", "仇", "秘", "解", "折", "朴", "翟", "查", "盖", "万俟", "尉迟"]
        let newCharacters     = ["审", "善", "球", "必", "谢", "蛇", "嫖", "宅", "渣", "哿", "莫奇", "玉迟"]
        
        for (index, element) in specialCharacters.enumerate() {
            if tempString.containsString(element) {
                tempString = tempString.stringByReplacingOccurrencesOfString(element, withString: newCharacters[index])
            }
        }
        return tempString
    }
    
    
}