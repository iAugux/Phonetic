//
//  PhoneticContacts+QuickSearch.swift
//  Phonetic
//
//  Created by Augus on 2/6/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Contacts
import Foundation

extension PhoneticContacts {
    /**
     *  Search name by enter `WXD` (not case-sensitive), then following names will be listed by example.
     *  "王晓东"、"万孝德" ...
     */
    func addPhoneticNameForQuickSearchIfNeeded(_ mutableContact: CNMutableContact, familyBrief: String = "", givenBrief: String = "") {
        guard let CNContactQuickSearchKey = ContactKeyForQuickSearch else { return }
        guard let originalPhoneticName = mutableContact.value(forKey: CNContactQuickSearchKey) as? String else { return }
        let newPhoneticName = familyBrief + givenBrief
        if overwriteExistingName {
            mutableContact.setValue(newPhoneticName, forKey: CNContactQuickSearchKey)
        } else if originalPhoneticName.isEmpty {
            mutableContact.setValue(newPhoneticName, forKey: CNContactQuickSearchKey)
        }
    }
}

extension PhoneticContacts {
    var ContactKeyForQuickSearch: String? {
        if enableNickname { return CNContactNicknameKey }
        guard enableCustomName else { return nil }
        if userDefaults.value(forKey: kQuickSearchKeyRawValue) == nil {
            userDefaults.set(QuickSearch.notes.rawValue, forKey: kQuickSearchKeyRawValue)
        }
        guard let quickSearchKey = userDefaults.value(forKey: kQuickSearchKeyRawValue) as? Int else { return nil }
        switch quickSearchKey {
        case QuickSearch.notes.rawValue:
            if #available(iOS 13.0, *) {
                return nil // Doesn't suport anymore
            } else {
                return CNContactNoteKey
            }
        case QuickSearch.middleName.rawValue:
            return CNContactPhoneticMiddleNameKey
        case QuickSearch.prefix.rawValue:
            return CNContactNamePrefixKey
        case QuickSearch.suffix.rawValue:
            return CNContactNameSuffixKey
        default: return nil
        }
    }
}

extension PhoneticContacts {
    var masterSwitchStatusIsOn: Bool {
        return userDefaults.bool(forKey: kAdditionalSettingsStatus, defaultValue: kAdditionalSettingsStatusDefaultBool)
    }

    var enableNickname: Bool {
        guard masterSwitchStatusIsOn else { return false }
        return userDefaults.bool(forKey: kEnableNickname, defaultValue: kEnableNicknameDefaultBool)
    }

    var enableCustomName: Bool {
        guard masterSwitchStatusIsOn else { return false }
        return userDefaults.bool(forKey: kEnableCustomName, defaultValue: kEnableCustomNameDefaultBool)
    }

    private var overwriteExistingName: Bool {
        guard masterSwitchStatusIsOn else { return false }
        guard enableNickname || enableCustomName else { return false }
        return userDefaults.bool(forKey: kOverwriteAlreadyExists, defaultValue: kOverwriteAlreadyExistsDefaultBool)
    }
}

extension CNContact {
    func quickSearchBriefName(_ quickSearchKey: String) -> String? {
        if quickSearchKey == CNContactNicknameKey { return nickname }
        if #available(iOS 13.0, *) {
            // doesn't support anymore
        } else {
            if quickSearchKey == CNContactNoteKey { return note }
        }
        if quickSearchKey == CNContactPhoneticMiddleNameKey { return phoneticMiddleName }
        if quickSearchKey == CNContactJobTitleKey { return jobTitle }
        if quickSearchKey == CNContactDepartmentNameKey { return departmentName }
        if quickSearchKey == CNContactOrganizationNameKey { return organizationName }
        if quickSearchKey == CNContactNamePrefixKey { return namePrefix }
        if quickSearchKey == CNContactNameSuffixKey { return nameSuffix }
        return nil
    }
}
