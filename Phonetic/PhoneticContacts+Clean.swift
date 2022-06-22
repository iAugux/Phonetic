//
//  PhoneticContacts+Clean.swift
//  Phonetic
//
//  Created by Augus on 2/13/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Contacts
import Foundation

extension PhoneticContacts {
    var keysToFetchIfNeeded: [String] {
        var keys = [String]()
        if shouldCleanPhoneticNicknameKeys { keys.append(CNContactNicknameKey) }
        if shouldCleanPhoneticMiddleNameKeys { keys.append(CNContactPhoneticMiddleNameKey) }
        if #available(iOS 13.0, *) {
            // Doesn't support anymore
        } else {
            if shouldCleanNotesKeys { keys.append(CNContactNoteKey) }
        }
        if shouldCleanPhoneticDepartmentKeys { keys.append(CNContactDepartmentNameKey) }
        if shouldCleanPhoneticCompanyKeys { keys.append(CNContactOrganizationNameKey) }
        if shouldCleanPhoneticJobTitleKeys { keys.append(CNContactJobTitleKey) }
        if shouldCleanPhoneticPrefixKeys { keys.append(CNContactNamePrefixKey) }
        if shouldCleanPhoneticSuffixKeys { keys.append(CNContactNameSuffixKey) }
        if shouldCleanSocialProfilesKeys { keys.append(CNContactSocialProfilesKey) }
        if shouldCleanInstantMessageAddressesKeys { keys.append(CNContactInstantMessageAddressesKey) }
        return keys
    }

    func removePhoneticKeysIfNeeded(_ mutableContact: CNMutableContact) {
        removePhoneticNicknameIfNeeded(mutableContact)
        removePhoneticMiddleNameIfNeeded(mutableContact)
        if #available(iOS 13.0, *) {
            // Doesn't support anymore
        } else {
            removeNotesKeysIfNeeded(mutableContact)
        }
        removePhoneticDepartmentKeysIfNeeded(mutableContact)
        removePhoneticCompanyKeysIfNeeded(mutableContact)
        removePhoneticJobTitleKeysIfNeeded(mutableContact)
        removePhoneticPrefixKeysIfNeeded(mutableContact)
        removePhoneticSuffixKeysIfNeeded(mutableContact)
        removeSocialProfilesKeysIfNeeded(mutableContact)
        removeInstantMessageAddressesKeysIfNeeded(mutableContact)
    }

    private func removePhoneticNicknameIfNeeded(_ mutableContact: CNMutableContact) {
        removePhoneticKeysIfNeeded(mutableContact, shouldClean: shouldCleanPhoneticNicknameKeys, key: CNContactNicknameKey)
    }

    private func removePhoneticMiddleNameIfNeeded(_ mutableContact: CNMutableContact) {
        removePhoneticKeysIfNeeded(mutableContact, shouldClean: shouldCleanPhoneticMiddleNameKeys, key: CNContactPhoneticMiddleNameKey)
    }

    private func removeNotesKeysIfNeeded(_ mutableContact: CNMutableContact) {
        removePhoneticKeysIfNeeded(mutableContact, shouldClean: shouldCleanNotesKeys, key: CNContactNoteKey)
    }

    private func removePhoneticDepartmentKeysIfNeeded(_ mutableContact: CNMutableContact) {
        removePhoneticKeysIfNeeded(mutableContact, shouldClean: shouldCleanPhoneticDepartmentKeys, key: CNContactDepartmentNameKey)
    }

    private func removePhoneticCompanyKeysIfNeeded(_ mutableContact: CNMutableContact) {
        removePhoneticKeysIfNeeded(mutableContact, shouldClean: shouldCleanPhoneticCompanyKeys, key: CNContactOrganizationNameKey)
    }

    private func removePhoneticJobTitleKeysIfNeeded(_ mutableContact: CNMutableContact) {
        removePhoneticKeysIfNeeded(mutableContact, shouldClean: shouldCleanPhoneticJobTitleKeys, key: CNContactJobTitleKey)
    }

    private func removePhoneticPrefixKeysIfNeeded(_ mutableContact: CNMutableContact) {
        removePhoneticKeysIfNeeded(mutableContact, shouldClean: shouldCleanPhoneticPrefixKeys, key: CNContactNamePrefixKey)
    }

    private func removePhoneticSuffixKeysIfNeeded(_ mutableContact: CNMutableContact) {
        removePhoneticKeysIfNeeded(mutableContact, shouldClean: shouldCleanPhoneticSuffixKeys, key: CNContactNameSuffixKey)
    }

    private func removeSocialProfilesKeysIfNeeded(_ mutableContact: CNMutableContact) {
        removeKeysArrayIfNeeded(mutableContact, shouldClean: shouldCleanSocialProfilesKeys, key: CNContactSocialProfilesKey)
    }

    private func removeInstantMessageAddressesKeysIfNeeded(_ mutableContact: CNMutableContact) {
        removeKeysArrayIfNeeded(mutableContact, shouldClean: shouldCleanInstantMessageAddressesKeys, key: CNContactInstantMessageAddressesKey)
    }

    private func removePhoneticKeysIfNeeded(_ mutableContact: CNMutableContact, shouldClean: Bool, key: String) {
        guard shouldClean else { return }
        if let _ = mutableContact.value(forKey: key) as? String {
            mutableContact.setValue("", forKey: key)
        }
    }

    private func removeKeysArrayIfNeeded(_ mutableContact: CNMutableContact, shouldClean: Bool, key: String) {
        guard shouldClean, let _ = mutableContact.value(forKey: key) as? NSArray else { return }
        mutableContact.setValue([], forKey: key)
    }
}

extension PhoneticContacts {
    private var shouldCleanPhoneticNicknameKeys: Bool {
        return shouldCleanPhoneticKey(kCleanPhoneticNickname, defaultKeyValue: kCleanPhoneticNicknameDefaultBool)
    }

    private var shouldCleanPhoneticMiddleNameKeys: Bool {
        return shouldCleanPhoneticKey(kCleanPhoneticMiddleName, defaultKeyValue: kCleanPhoneticMiddleNameDefaultBool)
    }

    var shouldCleanNotesKeys: Bool {
        return shouldCleanPhoneticKey(kCleanNotesKey, defaultKeyValue: kCleanNotesKeyDefaultBool)
    }

    private var shouldCleanPhoneticDepartmentKeys: Bool {
        return shouldCleanPhoneticKey(kCleanPhoneticDepartment, defaultKeyValue: kCleanPhoneticDepartmentDefaultBool)
    }

    private var shouldCleanPhoneticCompanyKeys: Bool {
        return shouldCleanPhoneticKey(kCleanPhoneticCompany, defaultKeyValue: kCleanPhoneticCompanyDefaultBool)
    }

    private var shouldCleanPhoneticJobTitleKeys: Bool {
        return shouldCleanPhoneticKey(kCleanPhoneticJobTitle, defaultKeyValue: kCleanPhoneticJobTitleDefaultBool)
    }

    private var shouldCleanPhoneticPrefixKeys: Bool {
        return shouldCleanPhoneticKey(kCleanPhoneticPrefix, defaultKeyValue: kCleanPhoneticPrefixDefaultBool)
    }

    private var shouldCleanPhoneticSuffixKeys: Bool {
        return shouldCleanPhoneticKey(kCleanPhoneticSuffix, defaultKeyValue: kCleanPhoneticSuffixDefaultBool)
    }

    // MARK: - Social Profiles Key
    private var shouldCleanSocialProfilesKeys: Bool {
        return shouldCleanPhoneticKey(kCleanSocialProfilesKeys, defaultKeyValue: kCleanSocialProfilesKeysDefaultBool)
    }

    // MARK: - Instant Message Addresses Key
    private var shouldCleanInstantMessageAddressesKeys: Bool {
        return shouldCleanPhoneticKey(kCleanInstantMessageAddressesKeys, defaultKeyValue: kCleanInstantMessageKeysDefaultBool)
    }

    // MARK: -
    private func shouldCleanPhoneticKey(_ key: String, defaultKeyValue: Bool) -> Bool {
        guard masterSwitchStatusIsOn else { return false }
        return userDefaults.bool(forKey: key, defaultValue: defaultKeyValue)
    }
}

extension PhoneticContacts {
    var messageOfCurrentKeysNeedToBeCleaned: String {
        var str = ""
        if shouldCleanPhoneticNicknameKeys ||
            shouldCleanPhoneticMiddleNameKeys ||
            shouldCleanNotesKeys ||
            shouldCleanPhoneticDepartmentKeys ||
            shouldCleanPhoneticCompanyKeys ||
            shouldCleanPhoneticJobTitleKeys ||
            shouldCleanPhoneticPrefixKeys ||
            shouldCleanPhoneticSuffixKeys ||
            shouldCleanSocialProfilesKeys ||
            shouldCleanInstantMessageAddressesKeys
        {
            str = NSLocalizedString(" And clean following keys you've chosen?", comment: "")
        }

        str += "\n\n"

        if shouldCleanPhoneticNicknameKeys { str.append(PhoneticKeys.nickname.key) }
        if shouldCleanPhoneticMiddleNameKeys { str.append(PhoneticKeys.middleName.key) }
        if shouldCleanNotesKeys { str.append(PhoneticKeys.notes.key) }
        if shouldCleanPhoneticDepartmentKeys { str.append(PhoneticKeys.department.key) }
        if shouldCleanPhoneticCompanyKeys { str.append(PhoneticKeys.company.key) }
        if shouldCleanPhoneticJobTitleKeys { str.append(PhoneticKeys.jobTitle.key) }
        if shouldCleanPhoneticPrefixKeys { str.append(PhoneticKeys.prefix.key) }
        if shouldCleanPhoneticSuffixKeys { str.append(PhoneticKeys.suffix.key) }
        if shouldCleanSocialProfilesKeys { str.append(PhoneticKeys.socialProfiles.key) }
        if shouldCleanInstantMessageAddressesKeys { str.append(PhoneticKeys.instantMessageAddresses.key) }

        str = String(str.dropLast(2))
        return String(format: str)
    }
}

private extension String {
    mutating func append(_ str: String) {
        self += str + "\n\n"
    }
}
