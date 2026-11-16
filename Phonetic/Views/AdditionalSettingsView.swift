// Created by Augus on 9/28/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI

struct AdditionalSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Sub Switches
    @AppStorage(kEnableNickname) private var enableNickname: Bool = kEnableNicknameDefaultBool
    @AppStorage(kEnableCustomName) private var enableCustomName: Bool = kEnableCustomNameDefaultBool
    @AppStorage(kOverwriteAlreadyExists) private var overwriteAlreadyExists: Bool = kOverwriteAlreadyExistsDefaultBool

    /// Quick Search Key
    @AppStorage(kQuickSearchKeyRawValue) private var quickSearchKeyRawValue: Int = 0

    // Clean Switches
    @AppStorage(kCleanPhoneticNickname) private var cleanNickname: Bool = kCleanPhoneticNicknameDefaultBool
    @AppStorage(kCleanPhoneticMiddleName) private var cleanMiddleName: Bool = kCleanPhoneticMiddleNameDefaultBool
    @AppStorage(kCleanNotesKey) private var cleanNotes: Bool = kCleanNotesKeyDefaultBool
    @AppStorage(kCleanPhoneticDepartment) private var cleanDepartment: Bool = kCleanPhoneticDepartmentDefaultBool
    @AppStorage(kCleanPhoneticCompany) private var cleanCompany: Bool = kCleanPhoneticCompanyDefaultBool
    @AppStorage(kCleanPhoneticJobTitle) private var cleanJobTitle: Bool = kCleanPhoneticJobTitleDefaultBool
    @AppStorage(kCleanPhoneticPrefix) private var cleanPrefix: Bool = kCleanPhoneticPrefixDefaultBool
    @AppStorage(kCleanPhoneticSuffix) private var cleanSuffix: Bool = kCleanPhoneticSuffixDefaultBool
    @AppStorage(kCleanSocialProfilesKeys) private var cleanSocialProfiles: Bool = kCleanSocialProfilesKeysDefaultBool
    @AppStorage(kCleanInstantMessageAddressesKeys) private var cleanInstantMessage: Bool = kCleanInstantMessageKeysDefaultBool
    @AppStorage(kAlwaysSeparatePinyin) private var alwaysSeparatePinyin: Bool = kAlwaysSeparatePinyinDefaultBool
    @AppStorage(kMassageCompanyKey) private var massageCompanyKey: Bool = kMassageCompanyKeyDefaultBool
    @AppStorage(kPhoneticFirstAndLastName) private var phoneticFirstAndLastName: Bool = kPhoneticFirstAndLastNameDefaultBool

    @State private var showWalkthrough = false
    @State private var pendingCleanSelection: CleanSelection?

    private var currentQuickSearchTitle: String {
        guard enableNickname || enableCustomName else { return String(localized: "Quick Search") }
        if enableNickname {
            return String(localized: "Quick Search: Nickname")
        }
        let field = QuickSearch(rawValue: quickSearchKeyRawValue) ?? .notes
        return String(localized: "Quick Search: \(field.key)")
    }

    private var allCommonFieldsSelected: Bool {
        cleanNickname && cleanMiddleName && cleanNotes && cleanDepartment && cleanCompany && cleanJobTitle && cleanPrefix && cleanSuffix
    }

    private var quickSearchSelection: Binding<QuickSearchSelection> {
        Binding(
            get: {
                if enableNickname {
                    return .nickname
                }
                guard enableCustomName else { return .off }
                return .field(QuickSearch(rawValue: quickSearchKeyRawValue) ?? .notes)
            },
            set: { selection in
                switch selection {
                case .off:
                    enableNickname = false
                    enableCustomName = false
                case .nickname:
                    enableNickname = true
                    enableCustomName = false
                case .field(let field):
                    enableNickname = false
                    quickSearchKeyRawValue = field.rawValue
                    enableCustomName = true
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                // Section: Whitelists
                Section {
                    NavigationLink(destination: WhitelistView()) {
                        Text("Whitelist")
                    }
                    NavigationLink("Version History") { ContactVersionsView() }
                }

                // Section: Quick Search
                Section {
                    Menu {
                        Picker("Quick Search", selection: quickSearchSelection) {
                            Text("Off").tag(QuickSearchSelection.off)
                            Text("Nickname").tag(QuickSearchSelection.nickname)
                            ForEach(0..<QuickSearch.cancel.rawValue, id: \.self) { idx in
                                if let field = QuickSearch(rawValue: idx) {
                                    Text(field.key).tag(QuickSearchSelection.field(field))
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(currentQuickSearchTitle)
                                .foregroundStyle(.primary)
                                .contentTransition(.opacity)

                            Spacer()

                            if !enableNickname, !enableCustomName {
                                Text("Off")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Image(systemName: "chevron.down")
                                .foregroundStyle(.secondary)
                        }
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: currentQuickSearchTitle)
                    }
                    Toggle("Overwrite Existing Text", isOn: $overwriteAlreadyExists)
                        .disabled(!enableNickname && !enableCustomName)
                        .tint(AppColor.accent)
                } header: {
                    Text("Quick Search")
                } footer: {
                    Text("Choose where to save search initials. Overwriting replaces existing text in that field when adding pinyin.")
                }

                Section {
                    Toggle("Separate Pinyin Syllables", isOn: $alwaysSeparatePinyin)
                        .tint(AppColor.accent)

                    Toggle("Use Company as Name", isOn: $massageCompanyKey)
                        .tint(AppColor.accent)

                    if DetectPreferredLanguage.isChineseLanguage {
                        Toggle("Add Phonetic Names", isOn: $phoneticFirstAndLastName)
                            .tint(AppColor.accent)
                    }
                } header: {
                    Text("Add Pinyin")
                } footer: {
                    Text("Use Company as Name copies the company name into the first name field for contacts with no first or last name when adding pinyin.")
                }

                // Section: Clean Phonetic Keys
                Section {
                    Toggle("Select Common Fields", isOn: Binding(
                        get: { allCommonFieldsSelected },
                        set: { val in
                            if val {
                                pendingCleanSelection = .all
                            } else {
                                toggleAllClean(false)
                            }
                        }
                    ))
                    .tint(AppColor.accent)

                    Toggle("Nickname", isOn: $cleanNickname)
                        .tint(AppColor.accent)

                    Toggle("Phonetic Middle Name", isOn: $cleanMiddleName)
                        .tint(AppColor.accent)

                    Toggle("Notes", isOn: $cleanNotes)
                        .tint(AppColor.accent)

                    Toggle("Department", isOn: $cleanDepartment)
                        .tint(AppColor.accent)

                    Toggle("Company", isOn: $cleanCompany)
                        .tint(AppColor.accent)

                    Toggle("Job Title", isOn: $cleanJobTitle)
                        .tint(AppColor.accent)

                    Toggle("Name Prefix", isOn: $cleanPrefix)
                        .tint(AppColor.accent)

                    Toggle("Name Suffix", isOn: $cleanSuffix)
                        .tint(AppColor.accent)

                    Toggle("Social Profiles", isOn: Binding(
                        get: { cleanSocialProfiles },
                        set: { value in
                            if value {
                                pendingCleanSelection = .socialProfiles
                            } else {
                                cleanSocialProfiles = false
                            }
                        }
                    ))
                        .tint(AppColor.accent)

                    Toggle("Instant Messaging Accounts", isOn: Binding(
                        get: { cleanInstantMessage },
                        set: { value in
                            if value {
                                pendingCleanSelection = .instantMessage
                            } else {
                                cleanInstantMessage = false
                            }
                        }
                    ))
                        .tint(AppColor.accent)

                } header: {
                    Text("Clear Contact Fields")
                } footer: {
                    Text("These options apply the next time you clear contact fields. Selected fields will be emptied, including text you entered manually. Select Common Fields controls the eight fields from Nickname through Name Suffix; social profiles and instant messaging accounts are managed separately.")
                        .transaction { $0.animation = nil }
                }

                // Section: Tutorial
                Section {
                    Button(action: { showWalkthrough = true }) {
                        Text("Tutorial")
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .compatibleGlass()
                    .tint(.primary)
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.pageBackground)
            .navigationTitle("Additional Settings")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Label("Close", systemImage: "xmark")
                    }
                    .tint(Color.primary)
                }
            }
            .alert("Include Fields When Clearing?", isPresented: Binding(
                get: { pendingCleanSelection != nil },
                set: {
                    if !$0 {
                        pendingCleanSelection = nil
                    }
                }
            ), presenting: pendingCleanSelection) { selection in
                Button("Include Fields") {
                    switch selection {
                    case .all:
                        toggleAllClean(true)
                    case .socialProfiles:
                        cleanSocialProfiles = true
                    case .instantMessage:
                        cleanInstantMessage = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { selection in
                Text(selection.message)
            }
            .sheet(isPresented: $showWalkthrough) {
                WalkthroughView()
            }
        }
    }

    private func toggleAllClean(_ val: Bool) {
        cleanNickname = val
        cleanMiddleName = val
        cleanNotes = val
        cleanDepartment = val
        cleanCompany = val
        cleanJobTitle = val
        cleanPrefix = val
        cleanSuffix = val
    }
}

private enum QuickSearchSelection: Hashable {
    case off, nickname, field(QuickSearch)
}

private enum CleanSelection {
    case all, socialProfiles, instantMessage

    var message: LocalizedStringKey {
        switch self {
        case .all:
            "This selects the common fields below. Their contents, including entries you added manually, will be erased when you clear contact fields. Social profiles and instant messaging accounts are selected separately."
        case .socialProfiles:
            "Social profiles will be removed the next time you clear contact fields. You can review and restore recorded changes while they remain in Version History on this device."
        case .instantMessage:
            "Instant messaging accounts will be removed the next time you clear contact fields. You can review and restore recorded changes while they remain in Version History on this device."
        }
    }
}
