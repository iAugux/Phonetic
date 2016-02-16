//
//  PhoneticContacts+QuickSearch.swift
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
    func addPhoneticNameForQuickSearchIfNeeded(mutableContact: CNMutableContact, familyBrief: String, givenBrief: String) {
        
        guard let CNContactQuickSearchKey = ContactKeyForQuickSearch else { return }
        
        if let originalPhoneticName = mutableContact.valueForKey(CNContactQuickSearchKey) as? String {
            
            let newPhoneticName = familyBrief + givenBrief
            
            if overwriteExistingName {
                mutableContact.setValue(newPhoneticName, forKey: CNContactQuickSearchKey)
            } else {
                if originalPhoneticName.isEmpty {
                    mutableContact.setValue(newPhoneticName, forKey: CNContactQuickSearchKey)
                }
            }
        }
    }
        
}

extension PhoneticContacts {
 
    internal var ContactKeyForQuickSearch: String? {
        
        if enableNickname {
            return CNContactNicknameKey
        }
        
        if enableCustomName {
            if userDefaults.valueForKey(kQuickSearchKey) == nil {
                userDefaults.setValue(QuickSearch.MiddleName.key, forKey: kQuickSearchKey)
                userDefaults.synchronize()
            }
            
            if let quickSearchKey = userDefaults.stringForKey(kQuickSearchKey) {
                switch quickSearchKey {
                case QuickSearch.MiddleName.key:
                    return CNContactPhoneticMiddleNameKey
                
                case QuickSearch.JobTitle.key:
                    return CNContactJobTitleKey
                    
                case QuickSearch.Department.key:
                    return CNContactDepartmentNameKey
                    
                case QuickSearch.Company.key:
                    return CNContactOrganizationNameKey
                    
                case QuickSearch.Prefix.key:
                    return CNContactNamePrefixKey
                    
                case QuickSearch.Suffix.key:
                    return CNContactNameSuffixKey
                    
                default: return nil
                }
            }
        }
        return nil
    }
    
}

extension PhoneticContacts {
    
    internal var masterSwitchStatusIsOn: Bool {
        return userDefaults.getBool(kAdditionalSettingsStatus, defaultKeyValue: kAdditionalSettingsStatusDefaultBool)
    }
    
    private var enableNickname: Bool {
        
        guard masterSwitchStatusIsOn else { return false }
        
        return userDefaults.getBool(kEnableNickname, defaultKeyValue: kEnableNicknameDefaultBool)
    }
    
    private var enableCustomName: Bool {
        
        guard masterSwitchStatusIsOn else { return false }
        
        return userDefaults.getBool(kEnableCustomName, defaultKeyValue: kEnableCustomNameDefaultBool)
    }
    
    private var overwriteExistingName: Bool {
        
        guard masterSwitchStatusIsOn else { return false }
        guard enableNickname || enableCustomName else { return false }
        
        return userDefaults.getBool(kOverwriteAlreadyExists, defaultKeyValue: kOverwriteAlreadyExistsDefaultBool)
    }
    
}