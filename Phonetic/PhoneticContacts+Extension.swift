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
    func addNickNameIfNeeded(mutableContact: CNMutableContact, familyBrief: String, givenBrief: String) {
        
        guard enableNickname else { return }
        
        if let originalNickname = mutableContact.valueForKey(CNContactNicknameKey) as? String {

            let newNickname = familyBrief + givenBrief

            if overwriteExistingNickname {
                mutableContact.setValue(newNickname, forKey: CNContactNicknameKey)
            } else {
                if originalNickname.isEmpty {
                    mutableContact.setValue(newNickname, forKey: CNContactNicknameKey)
                }
            }
        }
    }
    
    func removeNicknameIfNeeded(mutableContact: CNMutableContact) {
        
        if let _ = mutableContact.valueForKey(CNContactNicknameKey) as? String {
            // TODO: - Do not remove original nickname you entered before.
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
    
    private var enableNickname: Bool {
        
        guard masterSwitchStatusIsOn else { return false }
        
        if userDefaults.valueForKey(kEnableNickname) == nil {
            userDefaults.setBool(kEnableNicknameDefaultBool, forKey: kEnableNickname)
            userDefaults.synchronize()
        }
        return userDefaults.boolForKey(kEnableNickname)
    }
    
    private var overwriteExistingNickname: Bool {
        
        guard masterSwitchStatusIsOn else { return false }
        
        if userDefaults.valueForKey(kOverwriteNickname) == nil {
            userDefaults.setBool(kOverwriteNicknameDefaultBool, forKey: kOverwriteNickname)
            userDefaults.synchronize()
        }
        return userDefaults.boolForKey(kOverwriteNickname)
    }
    
}