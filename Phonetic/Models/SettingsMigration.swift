// Created by Augus on 10/27/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import Foundation

enum SettingsMigration {
    private static let versionKey = "settingsMigrationVersion"
    private static let currentVersion = 1
    private static let legacyMasterSwitchKey = "kAdditionalSettingsStatus"

    /// Converts the removed master switch into independent preferences without enabling paused work.
    /// Run synchronously at app startup, before settings views or contact processing can read defaults.
    /// The injected store lets regression tests use isolated suites instead of the user's preferences.
    static func migrate(_ defaults: UserDefaults = .standard) {
        guard defaults.integer(forKey: versionKey) < currentVersion else { return }

        // The old switch defaulted to ON. Reading an absent key with bool(forKey:) alone returns
        // false and would incorrectly disable nickname search for new installations. Only an
        // explicitly stored OFF value needs conversion; an ON or absent switch preserves settings.
        if defaults.object(forKey: legacyMasterSwitchKey) != nil, !defaults.bool(forKey: legacyMasterSwitchKey) {
            // These stored values could still be true while the old master switch suppressed their
            // effects. Persist their effective OFF state before removing the runtime guards, or an
            // upgrade could unexpectedly write initials, overwrite existing text, or clear fields.
            // Reset the aggregate cleaning toggle as well so the UI agrees with its individual flags.
            let pausedKeys = [
                kEnableNickname,
                kEnableCustomName,
                kOverwriteAlreadyExists,
                kEnableAllCleanPhonetic,
                kCleanPhoneticNickname,
                kCleanPhoneticMiddleName,
                kCleanNotesKey,
                kCleanPhoneticDepartment,
                kCleanPhoneticCompany,
                kCleanPhoneticJobTitle,
                kCleanPhoneticPrefix,
                kCleanPhoneticSuffix,
                kCleanSocialProfilesKeys,
                kCleanInstantMessageAddressesKeys,
            ]
            for key in pausedKeys {
                defaults.set(false, forKey: key)
            }

            // Preserve the selected search field, whitelist, and all other preferences. Pinyin
            // separation, company processing, and phonetic first/last names were never gated by the
            // master switch at runtime, so disabling them here would change existing behavior.
        }

        // Mark completion only after conversion. Repeating an unfinished conversion is harmless;
        // after completion, later launches must preserve options the user deliberately re-enables.
        // Keep the legacy value for downgrade compatibility, but never consult it during processing.
        defaults.set(currentVersion, forKey: versionKey)
    }
}
