@testable import Phonetic
import Contacts
import Foundation
import Testing

struct SettingsMigrationTests {
    private static let legacyKey = "kAdditionalSettingsStatus"
    private static let versionKey = "settingsMigrationVersion"
    private static let cleanFields: [(String, String)] = [
        (kCleanPhoneticNickname, CNContactNicknameKey),
        (kCleanPhoneticMiddleName, CNContactPhoneticMiddleNameKey),
        (kCleanNotesKey, CNContactNoteKey),
        (kCleanPhoneticDepartment, CNContactDepartmentNameKey),
        (kCleanPhoneticCompany, CNContactOrganizationNameKey),
        (kCleanPhoneticJobTitle, CNContactJobTitleKey),
        (kCleanPhoneticPrefix, CNContactNamePrefixKey),
        (kCleanPhoneticSuffix, CNContactNameSuffixKey),
        (kCleanSocialProfilesKeys, CNContactSocialProfilesKey),
        (kCleanInstantMessageAddressesKeys, CNContactInstantMessageAddressesKey),
    ]

    private static func preferences(_ defaults: UserDefaults) -> NSDictionary {
        var values = defaults.dictionaryRepresentation()
        values.removeValue(forKey: versionKey)
        return values as NSDictionary
    }

    private static func seedPreferences(_ defaults: UserDefaults) {
        defaults.set(true, forKey: kEnableNickname)
        defaults.set(true, forKey: kEnableCustomName)
        defaults.set(true, forKey: kOverwriteAlreadyExists)
        defaults.set(true, forKey: kEnableAllCleanPhonetic)
        for (key, _) in cleanFields {
            defaults.set(true, forKey: key)
        }
        defaults.set(QuickSearch.suffix.rawValue, forKey: kQuickSearchKeyRawValue)
        defaults.set(["preserved-contact"], forKey: kWhitelistIdentifiersKey)
        defaults.set(true, forKey: kAlwaysSeparatePinyin)
        defaults.set(true, forKey: kMassageCompanyKey)
        defaults.set(false, forKey: kPhoneticFirstAndLastName)
        defaults.set(true, forKey: kUseTones)
        defaults.set(false, forKey: kFixPolyphonicChar)
        defaults.set(true, forKey: kUpcasePinyin)
        defaults.set(true, forKey: displayedWalthroughKey)
    }

    @Test("fresh installation keeps nickname search enabled and extra cleaning disabled")
    static func freshInstallation() throws {
        let suiteName = "Phonetic.SettingsMigrationTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let before = preferences(defaults)
        SettingsMigration.migrate(defaults)
        try #require(preferences(defaults) == before, "Fresh installs must not acquire disabled flags")
        let engine = PhoneticContacts(userDefaults: defaults)
        try #require(engine.ContactKeyForQuickSearch == CNContactNicknameKey, "Default nickname search changed")
        try #require(engine.keysToFetchIfNeeded.isEmpty, "Extra cleaning must stay disabled by default")
    }

    @Test("legacy ON preserves every existing preference")
    static func legacyEnabled() throws {
        let suiteName = "Phonetic.SettingsMigrationTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        seedPreferences(defaults)
        defaults.set(true, forKey: legacyKey)
        let before = preferences(defaults)
        SettingsMigration.migrate(defaults)
        try #require(preferences(defaults) == before, "Legacy ON must preserve all stored values")
        let engine = PhoneticContacts(userDefaults: defaults)
        try #require(engine.ContactKeyForQuickSearch == CNContactNicknameKey, "Nickname precedence changed")
        try #require(Set(engine.keysToFetchIfNeeded) == Set(cleanFields.map(\.1)), "Enabled cleaning flags were lost")
    }

    @Test("absent legacy switch preserves custom choices")
    static func absentLegacySwitch() throws {
        let suiteName = "Phonetic.SettingsMigrationTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        seedPreferences(defaults)
        defaults.set(false, forKey: kEnableNickname)
        let before = preferences(defaults)
        SettingsMigration.migrate(defaults)
        try #require(preferences(defaults) == before, "An absent legacy key used to mean ON")
        try #require(PhoneticContacts(userDefaults: defaults).ContactKeyForQuickSearch == CNContactNameSuffixKey, "Custom field choice changed")
    }

    @Test("legacy OFF preserves effective behavior and unrelated preferences")
    static func legacyDisabled() throws {
        let suiteName = "Phonetic.SettingsMigrationTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        seedPreferences(defaults)
        defaults.set(false, forKey: legacyKey)
        var expected = defaults.dictionaryRepresentation()
        for key in [kEnableNickname, kEnableCustomName, kOverwriteAlreadyExists, kEnableAllCleanPhonetic] + cleanFields.map(\.0) {
            expected[key] = false
        }
        SettingsMigration.migrate(defaults)
        try #require(preferences(defaults) == expected as NSDictionary, "Legacy OFF changed unrelated values or missed a guarded flag")
        let engine = PhoneticContacts(userDefaults: defaults)
        try #require(engine.ContactKeyForQuickSearch == nil, "Legacy OFF must not write initials")
        try #require(engine.keysToFetchIfNeeded.isEmpty, "Legacy OFF must not fetch extra cleaning fields")
        let contact = sampleContact()
        let before = try #require(contact.copy() as? CNContact)
        engine.addPhoneticNameForQuickSearchIfNeeded(contact, familyBrief: "Y", givenBrief: "ZX")
        engine.removePhoneticKeysIfNeeded(contact)
        try #require(contact.isEqual(before), "Upgrade unexpectedly edited an in-memory contact")
    }

    @Test("legacy OFF overrides implicit nickname defaults")
    static func sparseLegacyDisabled() throws {
        let suiteName = "Phonetic.SettingsMigrationTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(false, forKey: legacyKey)
        SettingsMigration.migrate(defaults)
        let engine = PhoneticContacts(userDefaults: defaults)
        try #require(!engine.enableNickname && !engine.enableCustomName, "Implicit nickname default bypassed the OFF migration")
        try #require(engine.keysToFetchIfNeeded.isEmpty, "Sparse OFF migration enabled cleaning")
        try #require(defaults.object(forKey: kQuickSearchKeyRawValue) == nil, "Disabled search should not initialize a field choice")
        try #require(defaults.object(forKey: kAlwaysSeparatePinyin) == nil, "Unrelated absent settings must stay absent")
    }

    @Test("completed migration preserves later edits across defaults instances")
    static func repeatedLaunch() throws {
        let suiteName = "Phonetic.SettingsMigrationTests.Relaunch.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        seedPreferences(defaults)
        defaults.set(false, forKey: legacyKey)
        SettingsMigration.migrate(defaults)
        defaults.set(true, forKey: kEnableNickname)
        defaults.set(true, forKey: kCleanPhoneticPrefix)
        defaults.set(true, forKey: kOverwriteAlreadyExists)
        let before = preferences(defaults)
        // A fresh defaults instance must see the completed marker and preserve subsequent edits.
        let reloaded = try #require(UserDefaults(suiteName: suiteName))
        SettingsMigration.migrate(reloaded)
        try #require(preferences(reloaded) == before, "A repeated migration overwrote later user choices")
        let engine = PhoneticContacts(userDefaults: reloaded)
        let contact = sampleContact()
        engine.addPhoneticNameForQuickSearchIfNeeded(contact, familyBrief: "Y", givenBrief: "ZX")
        try #require(contact.nickname == "YZX", "Retained legacy OFF still blocks explicitly re-enabled search")
        engine.removePhoneticKeysIfNeeded(contact)
        try #require(contact.namePrefix.isEmpty, "Retained legacy OFF still blocks explicitly re-enabled cleaning")
        try #require(contact.note == "keep", "Re-enabling prefix cleaning affected another field")
    }

    @Test("unfinished conversion can safely retry")
    static func unfinishedMigration() throws {
        let suiteName = "Phonetic.SettingsMigrationTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        seedPreferences(defaults)
        defaults.set(false, forKey: legacyKey)
        defaults.set(false, forKey: kEnableNickname)
        defaults.set(false, forKey: kCleanPhoneticPrefix)
        defaults.set(0, forKey: versionKey)
        SettingsMigration.migrate(defaults)
        let engine = PhoneticContacts(userDefaults: defaults)
        try #require(engine.ContactKeyForQuickSearch == nil && engine.keysToFetchIfNeeded.isEmpty, "Retry left guarded options enabled")
        try #require(defaults.integer(forKey: versionKey) == 1, "Retry did not finish migration")
    }

    @Test("future migration versions are left untouched")
    static func futureVersion() throws {
        let suiteName = "Phonetic.SettingsMigrationTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        seedPreferences(defaults)
        defaults.set(false, forKey: legacyKey)
        defaults.set(2, forKey: versionKey)
        let before = defaults.dictionaryRepresentation() as NSDictionary
        SettingsMigration.migrate(defaults)
        try #require(defaults.dictionaryRepresentation() as NSDictionary == before, "Older code must not downgrade a future migration")
    }

    @Test("all search destinations and overwrite rules still work")
    static func quickSearchDestinations() throws {
        let suiteName = "Phonetic.SettingsMigrationTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: legacyKey)
        defaults.set(false, forKey: kEnableNickname)
        defaults.set(true, forKey: kEnableCustomName)
        SettingsMigration.migrate(defaults)
        let engine = PhoneticContacts(userDefaults: defaults)
        let destinations: [(QuickSearch, String)] = [
            (.notes, CNContactNoteKey), (.prefix, CNContactNamePrefixKey),
            (.suffix, CNContactNameSuffixKey), (.middleName, CNContactPhoneticMiddleNameKey),
        ]
        for (selection, key) in destinations {
            defaults.set(selection.rawValue, forKey: kQuickSearchKeyRawValue)
            defaults.set(false, forKey: kOverwriteAlreadyExists)
            try #require(engine.ContactKeyForQuickSearch == key, "Wrong search destination for \(selection)")
            let contact = CNMutableContact()
            engine.addPhoneticNameForQuickSearchIfNeeded(contact, familyBrief: "Y", givenBrief: "ZX")
            try #require(contact.value(forKey: key) as? String == "YZX", "Empty field did not receive initials")
            contact.setValue("keep", forKey: key)
            engine.addPhoneticNameForQuickSearchIfNeeded(contact, familyBrief: "Y", givenBrief: "ZX")
            try #require(contact.value(forKey: key) as? String == "keep", "Existing field was overwritten without permission")
            defaults.set(true, forKey: kOverwriteAlreadyExists)
            engine.addPhoneticNameForQuickSearchIfNeeded(contact, familyBrief: "Y", givenBrief: "ZX")
            try #require(contact.value(forKey: key) as? String == "YZX", "Explicit overwrite no longer works")
        }
    }

    @Test("each cleaning option independently clears only its own field")
    static func independentCleaning() throws {
        let suiteName = "Phonetic.SettingsMigrationTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(false, forKey: legacyKey)
        SettingsMigration.migrate(defaults)
        let engine = PhoneticContacts(userDefaults: defaults)
        for (enabledKey, contactKey) in cleanFields {
            for (key, _) in cleanFields {
                defaults.set(key == enabledKey, forKey: key)
            }
            try #require(engine.keysToFetchIfNeeded == [contactKey], "Cleaning fetch keys do not match the selected option")
            let contact = sampleContact()
            engine.removePhoneticKeysIfNeeded(contact)
            for (_, key) in cleanFields {
                if let value = contact.value(forKey: key) as? String {
                    try #require(value == (key == contactKey ? "" : "keep"), "Cleaning \(contactKey) incorrectly changed \(key)")
                } else if let values = contact.value(forKey: key) as? NSArray {
                    try #require(values.count == (key == contactKey ? 0 : 1), "Cleaning \(contactKey) incorrectly changed array \(key)")
                } else {
                    Issue.record("Unexpected field type for \(key)")
                }
            }
        }
    }

    private static func sampleContact() -> CNMutableContact {
        let contact = CNMutableContact()
        for (_, key) in cleanFields where key != CNContactSocialProfilesKey && key != CNContactInstantMessageAddressesKey {
            contact.setValue("keep", forKey: key)
        }
        contact.socialProfiles = [CNLabeledValue(label: CNLabelHome, value: CNSocialProfile(urlString: "https://example.com", username: "keep", userIdentifier: "keep", service: CNSocialProfileServiceTwitter))]
        contact.instantMessageAddresses = [CNLabeledValue(label: CNLabelHome, value: CNInstantMessageAddress(username: "keep", service: CNInstantMessageServiceSkype))]
        return contact
    }
}
