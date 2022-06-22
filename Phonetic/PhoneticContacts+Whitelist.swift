//
//  PhoneticContacts+Whitelist.swift
//  Phonetic
//
//  Created by Augus on 5/10/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Contacts
import Foundation

extension PhoneticContacts {
    private var keysToFetchForWhitelist: [String] {
        var keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneticGivenNameKey,
            CNContactPhoneticFamilyNameKey,
            CNContactThumbnailImageDataKey,
            CNContactImageDataAvailableKey,
        ]
        if ContactKeyForQuickSearch != nil { keys.append(ContactKeyForQuickSearch!) }
        return keys
    }

    var allContactsForWhitelist: [CNContact] {
        return fetchAllContacts(keysToFetch: keysToFetchForWhitelist as [CNKeyDescriptor])
    }

    func fetchContactsMatchingWith(_ str: String) -> [CNContact]? {
        AppDelegate.shared.requestContactsAccess { accessGranted in
            guard accessGranted else { return }
        }
        var keys = keysToFetchForWhitelist
        keys.append(CNContactPhoneNumbersKey)
        let contacts = try? contactStore.unifiedContacts(matching: CNContact.predicateForContacts(matchingName: str), keysToFetch: keys as [CNKeyDescriptor])
        return contacts
    }

    func fetchContactsMatchingWith(_ str: String, closure: @escaping ([CNContact]) -> Void) {
        var k = keysToFetchForWhitelist
        k.append(CNContactPhoneNumbersKey)
        let keys = k as [CNKeyDescriptor]
        guard !str.isPhoneNumber else {
            fetchContactsWithPhoneNumber(str, keysToFetch: keys, closure: closure)
            return
        }
        DispatchQueue.global(qos: .background).async {
            let contacts = try? self.contactStore.unifiedContacts(matching: CNContact.predicateForContacts(matchingName: str), keysToFetch: keys)
            DispatchQueue.main.async {
                closure(contacts ?? [])
            }
        }
    }

    private func fetchContactsWithPhoneNumber(_ number: String, keysToFetch: [CNKeyDescriptor], closure: @escaping ([CNContact]) -> Void) {
        var contacts = [CNContact]()
        DispatchQueue.global(qos: .background).async {
            try? self.contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: keysToFetch)) {
                contact, _ in
                if !contact.phoneNumbers.isEmpty {
                    let phoneNumberToCompareAgainst = number.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
                    for phoneNumber in contact.phoneNumbers {
                        let phoneNumberString = phoneNumber.value.stringValue
                        let phoneNumberToCompare = phoneNumberString.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
                        if phoneNumberToCompare.contains(phoneNumberToCompareAgainst) {
                            contacts.append(contact)
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                closure(contacts)
            }
        }
    }

    func fetchContactsWithIdentifiers(_ identifiers: NSArray) -> [CNContact]? {
        guard let identifiers = identifiers as? [String] else { return nil }
        let contacts = try? contactStore.unifiedContacts(matching: CNContact.predicateForContacts(withIdentifiers: identifiers), keysToFetch: keysToFetchForWhitelist as [CNKeyDescriptor])
        return contacts
    }
}

private extension String {
    var isPhoneNumber: Bool {
        let formatted = self.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
        return formatted.count > 2 && Int(formatted) != nil
    }
}
