// Created by Augus on 5/10/16
// Copyright © 2016 Augus <iAugux@gmail.com>

import Contacts
import Foundation

extension PhoneticContacts {
    var keysToFetchForWhitelist: [CNKeyDescriptor] {
        // The formatter may read more than given/family names. Request its descriptor alongside
        // every fallback and row field to avoid CNPropertyNotFetchedException on fetched contacts.
        var keys: [CNKeyDescriptor] = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName)]
        keys.append(contentsOf: [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactMiddleNameKey,
            CNContactNamePrefixKey,
            CNContactNameSuffixKey,
            CNContactOrganizationNameKey,
            CNContactNicknameKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactPhoneticGivenNameKey,
            CNContactPhoneticFamilyNameKey,
            CNContactThumbnailImageDataKey,
            CNContactImageDataAvailableKey,
        ].map { $0 as CNKeyDescriptor })
        if let quickSearchKey = ContactKeyForQuickSearch {
            keys.append(quickSearchKey as CNKeyDescriptor)
        }
        return keys
    }
}

extension CNContact {
    var whitelistDisplayName: String {
        if let name = whitelistName {
            return name
        }
        // Phone/email-only contacts still need an identifiable row and editor title.
        let identifiers = phoneNumbers.map { $0.value.stringValue } + emailAddresses.map { $0.value as String }
        for identifier in identifiers {
            let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return String(localized: "Unnamed Contact")
    }

    private var whitelistName: String? {
        // The system formatter can fall back to a nickname even in full-name mode. Only use it
        // for actual personal-name components so company/nickname fallbacks keep a stable order.
        let hasPersonalName = [givenName, familyName, middleName, namePrefix, nameSuffix].contains {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if hasPersonalName, let fullName = CNContactFormatter.string(from: self, style: .fullName)?.trimmingCharacters(in: .whitespacesAndNewlines), !fullName.isEmpty {
            return fullName
        }
        for name in [organizationName, nickname] {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return nil
    }

    func matchesWhitelistSearch(_ searchText: String) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        let names = [
            whitelistName ?? "",
            organizationName,
            nickname,
            "\(familyName)\(givenName)",
            "\(familyName) \(givenName)",
            "\(givenName) \(familyName)",
            "\(phoneticFamilyName)\(phoneticGivenName)",
            "\(phoneticFamilyName) \(phoneticGivenName)",
            "\(phoneticGivenName) \(phoneticFamilyName)",
        ]
        if names.contains(where: { $0.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil }) {
            return true
        }
        if emailAddresses.contains(where: { ($0.value as String).range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil }) {
            return true
        }
        let digits = query.filter(\.isNumber)
        guard digits.count > 2, isKeyAvailable(CNContactPhoneNumbersKey) else { return false }
        return phoneNumbers.contains { $0.value.stringValue.filter(\.isNumber).contains(digits) }
    }
}
