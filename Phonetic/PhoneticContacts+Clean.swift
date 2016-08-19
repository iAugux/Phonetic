//
//  PhoneticContacts+Clean.swift
//  Phonetic
//
//  Created by Augus on 2/13/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation
import Contacts

extension PhoneticContacts {
    
    var keysToFetchIfNeeded: [String] {
        var keys = [String]()
        
        if shouldCleanPhoneticNicknameKeys { keys.append(CNContactNicknameKey) }
        
        if shouldCleanPhoneticMiddleNameKeys { keys.append(CNContactPhoneticMiddleNameKey) }
        
        if shouldCleanPhoneticDepartmentKeys { keys.append(CNContactDepartmentNameKey) }
        
        if shouldCleanPhoneticCompanyKeys { keys.append(CNContactOrganizationNameKey) }
        
        if shouldCleanPhoneticJobTitleKeys { keys.append(CNContactJobTitleKey) }
        
        if shouldCleanPhoneticPrefixKeys { keys.append(CNContactNamePrefixKey) }
        
        if shouldCleanPhoneticSuffixKeys { keys.append(CNContactNameSuffixKey) }
        
        if shouldCleanSocialProfilesKeys { keys.append(CNContactSocialProfilesKey) }
        
        if shouldCleanInstantMessageAddressesKeys{ keys.append(CNContactInstantMessageAddressesKey) }
        
        return keys
    }
    
    func removePhoneticKeysIfNeeded(_ mutableContact: CNMutableContact) {
        removePhoneticNicknameIfNeeded(mutableContact)
        removePhoneticMiddleNameIfNeeded(mutableContact)
        removePhoneticDepartmentKeysIfNeeded(mutableContact)
        removePhoneticCompanyKeysIfNeeded(mutableContact)
        removePhoneticJobTitleKeysIfNeeded(mutableContact)
        removePhoneticPrefixKeysIfNeeded(mutableContact)
        removePhoneticSuffixKeysIfNeeded(mutableContact)
        removeSocialProfilesKeysIfNeeded(mutableContact)
        removeInstantMessageAddressesKeysIfNeeded(mutableContact)
    }
    
    fileprivate func removePhoneticNicknameIfNeeded(_ mutableContact: CNMutableContact) {
        removePhoneticKeysIfNeeded(mutableContact, shouldClean: shouldCleanPhoneticNicknameKeys, key: CNContactNicknameKey)
    }
    
    fileprivate func removePhoneticMiddleNameIfNeeded(_ mutableContact: CNMutableContact) {
        removePhoneticKeysIfNeeded(mutableContact, shouldClean: shouldCleanPhoneticMiddleNameKeys, key: CNContactPhoneticMiddleNameKey)
    }
    
    fileprivate func removePhoneticDepartmentKeysIfNeeded(_ mutableContact: CNMutableContact) {
        removePhoneticKeysIfNeeded(mutableContact, shouldClean: shouldCleanPhoneticDepartmentKeys, key: CNContactDepartmentNameKey)
    }
    
    fileprivate func removePhoneticCompanyKeysIfNeeded(_ mutableContact: CNMutableContact) {
        removePhoneticKeysIfNeeded(mutableContact, shouldClean: shouldCleanPhoneticCompanyKeys, key: CNContactOrganizationNameKey)
    }
    
    fileprivate func removePhoneticJobTitleKeysIfNeeded(_ mutableContact: CNMutableContact) {
        removePhoneticKeysIfNeeded(mutableContact, shouldClean: shouldCleanPhoneticJobTitleKeys, key: CNContactJobTitleKey)
    }
    
    fileprivate func removePhoneticPrefixKeysIfNeeded(_ mutableContact: CNMutableContact) {
        removePhoneticKeysIfNeeded(mutableContact, shouldClean: shouldCleanPhoneticPrefixKeys, key: CNContactNamePrefixKey)
    }
    
    fileprivate func removePhoneticSuffixKeysIfNeeded(_ mutableContact: CNMutableContact) {
        removePhoneticKeysIfNeeded(mutableContact, shouldClean: shouldCleanPhoneticSuffixKeys, key: CNContactNameSuffixKey)
    }
    
    fileprivate func removeSocialProfilesKeysIfNeeded(_ mutableContact: CNMutableContact) {
        removeKeysArrayIfNeeded(mutableContact, shouldClean: shouldCleanSocialProfilesKeys, key: CNContactSocialProfilesKey)
    }
    
    fileprivate func removeInstantMessageAddressesKeysIfNeeded(_ mutableContact: CNMutableContact) {
        removeKeysArrayIfNeeded(mutableContact, shouldClean: shouldCleanInstantMessageAddressesKeys, key: CNContactInstantMessageAddressesKey)
    }
    
    fileprivate func removePhoneticKeysIfNeeded(_ mutableContact: CNMutableContact, shouldClean: Bool, key: String) {
        
        guard shouldClean else { return }
        
        if let _ = mutableContact.value(forKey: key) as? String {
            mutableContact.setValue("", forKey: key)
        }
    }
    
    fileprivate func removeKeysArrayIfNeeded(_ mutableContact: CNMutableContact, shouldClean: Bool, key: String) {
        
        guard shouldClean, let _ = mutableContact.value(forKey: key) as? NSArray else { return }
        
        mutableContact.setValue([], forKey: key)
    }
    
}

extension PhoneticContacts {
    
    fileprivate var shouldCleanPhoneticNicknameKeys: Bool {
        return shouldCleanPhoneticKey(kCleanPhoneticNickname, defaultKeyValue: kCleanPhoneticNicknameDefaultBool)
    }
    
    fileprivate var shouldCleanPhoneticMiddleNameKeys: Bool {
        return shouldCleanPhoneticKey(kCleanPhoneticMiddleName, defaultKeyValue: kCleanPhoneticMiddleNameDefaultBool)
    }
    
    fileprivate var shouldCleanPhoneticDepartmentKeys: Bool {
        return shouldCleanPhoneticKey(kCleanPhoneticDepartment, defaultKeyValue: kCleanPhoneticDepartmentDefaultBool)
    }
    
    fileprivate var shouldCleanPhoneticCompanyKeys: Bool {
        return shouldCleanPhoneticKey(kCleanPhoneticCompany, defaultKeyValue: kCleanPhoneticCompanyDefaultBool)
    }
    
    fileprivate var shouldCleanPhoneticJobTitleKeys: Bool {
        return shouldCleanPhoneticKey(kCleanPhoneticJobTitle, defaultKeyValue: kCleanPhoneticJobTitleDefaultBool)
    }
    
    fileprivate var shouldCleanPhoneticPrefixKeys: Bool {
        return shouldCleanPhoneticKey(kCleanPhoneticPrefix, defaultKeyValue: kCleanPhoneticPrefixDefaultBool)
    }
    
    fileprivate var shouldCleanPhoneticSuffixKeys: Bool {
        return shouldCleanPhoneticKey(kCleanPhoneticSuffix, defaultKeyValue: kCleanPhoneticSuffixDefaultBool)
    }
    
    // MARK: - Social Profiles Key
    fileprivate var shouldCleanSocialProfilesKeys: Bool {
        return shouldCleanPhoneticKey(kCleanSocialProfilesKeys, defaultKeyValue: kCleanSocialProfilesKeysDefaultBool)
    }
    
    // MARK: - Instant Message Addresses Key
    fileprivate var shouldCleanInstantMessageAddressesKeys: Bool {
        return shouldCleanPhoneticKey(kCleanInstantMessageAddressesKeys, defaultKeyValue: kCleanInstantMessageKeysDefaultBool)
    }
    
    // MARK: -
    fileprivate func shouldCleanPhoneticKey(_ key: String, defaultKeyValue: Bool) -> Bool {
        
        guard masterSwitchStatusIsOn else { return false }

        return userDefaults.bool(forKey: key, defaultValue: defaultKeyValue)
    }
    
}

extension PhoneticContacts {
    
    internal var messageOfCurrentKeysNeedToBeCleaned: String {
        var str = ""
        
        if shouldCleanPhoneticNicknameKeys ||
            shouldCleanPhoneticMiddleNameKeys ||
            shouldCleanPhoneticDepartmentKeys ||
            shouldCleanPhoneticCompanyKeys ||
            shouldCleanPhoneticJobTitleKeys ||
            shouldCleanPhoneticPrefixKeys ||
            shouldCleanPhoneticSuffixKeys ||
            shouldCleanSocialProfilesKeys ||
            shouldCleanInstantMessageAddressesKeys {
                str = NSLocalizedString(" And clean following keys you've chosen?", comment: "")
        }
        
//        str += NSLocalizedString(" This can not be revoked!!", comment: "")
        str += "\n\n"
        
        if shouldCleanPhoneticNicknameKeys { str.append(PhoneticKeys.Nickname.key) }
        if shouldCleanPhoneticMiddleNameKeys { str.append(PhoneticKeys.MiddleName.key) }
        if shouldCleanPhoneticDepartmentKeys { str.append(PhoneticKeys.Department.key) }
        if shouldCleanPhoneticCompanyKeys { str.append(PhoneticKeys.Company.key) }
        if shouldCleanPhoneticJobTitleKeys { str.append(PhoneticKeys.JobTitle.key) }
        if shouldCleanPhoneticPrefixKeys { str.append(PhoneticKeys.Prefix.key) }
        if shouldCleanPhoneticSuffixKeys { str.append(PhoneticKeys.Suffix.key) }
        if shouldCleanSocialProfilesKeys { str.append(PhoneticKeys.SocialProfiles.key) }
        if shouldCleanInstantMessageAddressesKeys{ str.append(PhoneticKeys.InstantMessageAddresses.key) }
        
        str = String(str.characters.dropLast(2))
        
        return String(format: str)
    }
}

extension String {
    
    fileprivate mutating func append(_ str: String) {
        self += str + "\n\n"
    }
}

extension PhoneticContacts {
    
    //    func removePhoneticNicknameForTestFlightUsersToFixPreviousBug(mutableContact: CNMutableContact) {
    //
    //        guard Config.appConfiguration == .TestFlight || Config.appConfiguration == .Debug else { return }
    //
    //        if let _ = mutableContact.valueForKey(CNContactNicknameKey) as? String {
    //            mutableContact.setValue("", forKey: CNContactNicknameKey)
    //        }
    //    }
    
}
