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
    func addPhoneticNameForQuickSearchIfNeeded(_ mutableContact: CNMutableContact, familyBrief: String, givenBrief: String) {
        
        guard let CNContactQuickSearchKey = ContactKeyForQuickSearch else { return }
        
        if let originalPhoneticName = mutableContact.value(forKey: CNContactQuickSearchKey) as? String {
            
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
            if userDefaults.value(forKey: kQuickSearchKeyRawValue) == nil {
                userDefaults.set(QuickSearch.middleName.rawValue, forKey: kQuickSearchKeyRawValue)
                userDefaults.synchronize()
            }
            
            if let quickSearchKey = userDefaults.value(forKey: kQuickSearchKeyRawValue) as? Int {
                switch quickSearchKey {
                case QuickSearch.middleName.rawValue:
                    return CNContactPhoneticMiddleNameKey
                
                case QuickSearch.jobTitle.rawValue:
                    return CNContactJobTitleKey
                    
                case QuickSearch.department.rawValue:
                    return CNContactDepartmentNameKey
                    
                case QuickSearch.company.rawValue:
                    return CNContactOrganizationNameKey
                    
                case QuickSearch.prefix.rawValue:
                    return CNContactNamePrefixKey
                    
                case QuickSearch.suffix.rawValue:
                    return CNContactNameSuffixKey
                    
                default: return nil
                }
            }
        }
        return nil
    }
    
}

extension PhoneticContacts {
    
    var masterSwitchStatusIsOn: Bool {
        return userDefaults.getBool(kAdditionalSettingsStatus, defaultKeyValue: kAdditionalSettingsStatusDefaultBool)
    }
    
    var enableNickname: Bool {
        
        guard masterSwitchStatusIsOn else { return false }
        
        return userDefaults.getBool(kEnableNickname, defaultKeyValue: kEnableNicknameDefaultBool)
    }
    
    var enableCustomName: Bool {
        
        guard masterSwitchStatusIsOn else { return false }
        
        return userDefaults.getBool(kEnableCustomName, defaultKeyValue: kEnableCustomNameDefaultBool)
    }
    
    private var overwriteExistingName: Bool {
        
        guard masterSwitchStatusIsOn else { return false }
        guard enableNickname || enableCustomName else { return false }
        
        return userDefaults.getBool(kOverwriteAlreadyExists, defaultKeyValue: kOverwriteAlreadyExistsDefaultBool)
    }
    
}
