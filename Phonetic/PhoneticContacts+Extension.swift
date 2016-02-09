//
//  PhoneticContacts+Extension.swift
//  Phonetic
//
//  Created by Augus on 2/6/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation
import Contacts

extension PhoneticContacts {
    
    /**
     *  Search name by enter `WXD` (not case-sensitive), then following names will be listed by example.
     *  "王晓东"、"万孝德" ...
     */
    func addPhoneticMiddleNameIfNeeded(mutableContact: CNMutableContact, familyBrief: String, givenBrief: String) {
        
        guard enableMiddleName else { return }
        
        if let originalMiddleName = mutableContact.valueForKey(CNContactPhoneticMiddleNameKey) as? String {

            let newMiddleName = "【" + familyBrief + givenBrief + "】"

            if overwriteExistingMiddleName {
                mutableContact.setValue(newMiddleName, forKey: CNContactPhoneticMiddleNameKey)
            } else {
                if originalMiddleName.isEmpty {
                    mutableContact.setValue(newMiddleName, forKey: CNContactPhoneticMiddleNameKey)
                }
            }
        }
    }
    
    func removePhoneticMiddleNameIfNeeded(mutableContact: CNMutableContact) {
        
        if let _ = mutableContact.valueForKey(CNContactPhoneticMiddleNameKey) as? String {
            // TODO: - Do not remove original middle name if you entered before.
            mutableContact.setValue("", forKey: CNContactPhoneticMiddleNameKey)
        }
    }
    
    func removePhoneticNicknameForTestFlightUsersToFixPreviousBug(mutableContact: CNMutableContact) {
        
        guard Config.appConfiguration == .TestFlight || Config.appConfiguration == .Debug else { return }
        
        if let _ = mutableContact.valueForKey(CNContactNicknameKey) as? String {
            mutableContact.setValue("", forKey: CNContactNicknameKey)
        }
    }
    
    
}

extension PhoneticContacts {
    
    private var masterSwitchStatusIsOn: Bool {
        if userDefaults.valueForKey(kAdditionalSettingsStatus) == nil {
            userDefaults.setBool(kAdditionalSettingsStatusDefaultBool, forKey: kAdditionalSettingsStatus)
            userDefaults.synchronize()
        }
        return userDefaults.boolForKey(kAdditionalSettingsStatus)
    }
    
    private var enableMiddleName: Bool {
        
        guard masterSwitchStatusIsOn else { return false }
        
        if userDefaults.valueForKey(kEnableMiddleName) == nil {
            userDefaults.setBool(kEnableMiddleNameDefaultBool, forKey: kEnableMiddleName)
            userDefaults.synchronize()
        }
        return userDefaults.boolForKey(kEnableMiddleName)
    }
    
    private var overwriteExistingMiddleName: Bool {
        
        guard masterSwitchStatusIsOn else { return false }
        
        if userDefaults.valueForKey(kOverwriteMiddleName) == nil {
            userDefaults.setBool(kOverwriteMiddleNameDefaultBool, forKey: kOverwriteMiddleName)
            userDefaults.synchronize()
        }
        return userDefaults.boolForKey(kOverwriteMiddleName)
    }
    
}