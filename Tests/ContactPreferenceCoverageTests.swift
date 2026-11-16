@testable import Phonetic
import Contacts
import Foundation
import Testing

private let cleanOptions: [(key: String, title: PhoneticKeys)] = [
    (kCleanPhoneticNickname, .nickname), (kCleanPhoneticMiddleName, .middleName),
    (kCleanNotesKey, .notes), (kCleanPhoneticDepartment, .department),
    (kCleanPhoneticCompany, .company), (kCleanPhoneticJobTitle, .jobTitle),
    (kCleanPhoneticPrefix, .prefix), (kCleanPhoneticSuffix, .suffix),
    (kCleanSocialProfilesKeys, .socialProfiles), (kCleanInstantMessageAddressesKeys, .instantMessageAddresses),
]

private final class PreferenceFixture {
    private let suite = "ContactPreferences.\(UUID().uuidString)"
    let defaults: UserDefaults
    let engine: PhoneticContacts

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suite))
        engine = PhoneticContacts(userDefaults: defaults)
        for option in cleanOptions {
            defaults.set(false, forKey: option.key)
        }
    }

    deinit { defaults.removePersistentDomain(forName: suite) }
}

struct ContactPreferenceCoverageTests {
    @Test("Whitelist brief reads the requested contact field without falling back to another",
          arguments: [
              CNContactNicknameKey,
              CNContactNoteKey,
              CNContactPhoneticMiddleNameKey,
              CNContactJobTitleKey,
              CNContactDepartmentNameKey,
              CNContactOrganizationNameKey,
              CNContactNamePrefixKey,
              CNContactNameSuffixKey,
          ])
    static func briefFieldLookup(key: String) {
        let contact = CNMutableContact()
        contact.nickname = "Other field"
        let expected = "Value for \(key)"
        contact.setValue(expected, forKey: key)
        #expect(contact.quickSearchBriefName(key) == expected)
        contact.setValue("", forKey: key)
        #expect(contact.quickSearchBriefName(key) == "")
    }

    @Test("Unsupported brief fields are rejected rather than read through KVC")
    static func unsupportedBriefField() {
        let contact = CNMutableContact()
        contact.givenName = "Ada"
        #expect(contact.quickSearchBriefName(CNContactGivenNameKey) == nil)
        #expect(contact.quickSearchBriefName("unknownKey") == nil)
    }

    @Test("Invalid quick-search preferences cannot overwrite contact fields",
          arguments: [-1, QuickSearch.cancel.rawValue, 999])
    static func invalidSearchDestination(rawValue: Int) throws {
        let f = try PreferenceFixture()
        f.defaults.set(false, forKey: kEnableNickname)
        f.defaults.set(true, forKey: kEnableCustomName)
        f.defaults.set(true, forKey: kOverwriteAlreadyExists)
        f.defaults.set(rawValue, forKey: kQuickSearchKeyRawValue)
        let contact = CNMutableContact()
        contact.nickname = "Keep nickname"
        contact.note = "Keep note"
        #expect(f.engine.ContactKeyForQuickSearch == nil)
        f.engine.addPhoneticNameForQuickSearchIfNeeded(contact, familyBrief: "L", givenBrief: "MQ")
        #expect(contact.nickname == "Keep nickname" && contact.note == "Keep note")
    }

    @Test("The clean confirmation lists exactly the single selected field",
          arguments: cleanOptions.map(\.key))
    static func singleCleanField(key: String) throws {
        let f = try PreferenceFixture()
        f.defaults.set(true, forKey: key)
        let option = try #require(cleanOptions.first { $0.key == key })
        let paragraphs = f.engine.messageOfCurrentKeysNeedToBeCleaned.components(separatedBy: "\n\n")
        #expect(paragraphs.count == 2)
        #expect(paragraphs.last == option.title.key)
    }

    @Test("Clean confirmations handle no optional fields and all optional fields without empty suffixes",
          arguments: [false, true])
    static func cleanFieldExtremes(allSelected: Bool) throws {
        let f = try PreferenceFixture()
        for option in cleanOptions {
            f.defaults.set(allSelected, forKey: option.key)
        }
        let message = f.engine.messageOfCurrentKeysNeedToBeCleaned
        let paragraphs = message.components(separatedBy: "\n\n")
        #expect(paragraphs.count == (allSelected ? cleanOptions.count + 1 : 1))
        #expect(!message.hasSuffix("\n") && !message.isEmpty)
        if allSelected {
            #expect(Array(paragraphs.dropFirst()) == cleanOptions.map { $0.title.key })
        }
    }
}

@MainActor
struct EditableContactChangeTests {
    @Test("Existing whitespace does not enable Save, and restoring values clears the dirty state")
    static func normalizedPhoneticFields() {
        let contact = CNMutableContact()
        contact.phoneticFamilyName = " Wang "
        contact.phoneticGivenName = " Xiao "

        func changed(family: String, given: String) -> Bool {
            EditableContactView.fieldsHaveChanges(
                contact: contact,
                phoneticFamilyName: family,
                phoneticGivenName: given,
                quickSearchText: "",
                quickSearchKey: nil
            )
        }

        #expect(!changed(family: " Wang ", given: " Xiao "))
        #expect(!changed(family: "Wang", given: "Xiao"))
        #expect(!changed(family: "  Wang  ", given: " Xiao "))
        #expect(changed(family: "Zhang", given: " Xiao "))
        #expect(changed(family: " Wang ", given: "Ming"))
        #expect(!changed(family: " Wang ", given: " Xiao "))
    }

    @Test("Quick-search changes respect trimmed stored values and the configured field")
    static func normalizedQuickSearchField() {
        let contact = CNMutableContact()
        contact.phoneticFamilyName = "Wang"
        contact.phoneticGivenName = "Xiao"
        contact.nickname = " WX "

        func changed(quickSearch: String, key: String?) -> Bool {
            EditableContactView.fieldsHaveChanges(
                contact: contact,
                phoneticFamilyName: "Wang",
                phoneticGivenName: "Xiao",
                quickSearchText: quickSearch,
                quickSearchKey: key
            )
        }

        #expect(!changed(quickSearch: " WX ", key: CNContactNicknameKey))
        #expect(!changed(quickSearch: "WX", key: CNContactNicknameKey))
        #expect(changed(quickSearch: "WZ", key: CNContactNicknameKey))
        #expect(!changed(quickSearch: "WX", key: CNContactNicknameKey))
        #expect(!changed(quickSearch: "WZ", key: nil))
    }
}
