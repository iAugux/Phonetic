// Created by Augus on 2/6/16
// Copyright © 2016 Augus <iAugux@gmail.com>

import Foundation

struct Phonetic {
    var brief: String
    var value: String

    static func joinSyllables(_ parts: [String], separated: Bool, upcase: Bool) -> String {
        parts.filter { !$0.isEmpty }.enumerated().map { index, part in
            separated || upcase || index == 0 ? part.capitalized : part
        }.joined(separator: separated ? " " : "")
    }

    static func exampleName(useTones: Bool, separated: Bool, upcase: Bool) -> String {
        let family = useTones ? "Lín" : "Lin"
        let given = joinSyllables(useTones ? ["mù", "qíng"] : ["mu", "qing"], separated: separated, upcase: upcase)
        return "\(family) \(given)"
    }
}

enum QuickSearch: Int {
    case notes
    case prefix
    case suffix
    case middleName
    case cancel

    var key: String {
        switch self {
        case .notes:
            return String(localized: "Notes")
        case .prefix:
            return String(localized: "Name Prefix")
        case .suffix:
            return String(localized: "Name Suffix")
        case .middleName:
            return String(localized: "Phonetic Middle Name")
        case .cancel:
            return String(localized: "Cancel")
        }
    }
}

enum PhoneticKeys: String {
    case nickname
    case notes
    case department
    case company
    case jobTitle
    case prefix
    case suffix
    case middleName
    case socialProfiles
    case instantMessageAddresses

    var key: String {
        switch self {
        case .nickname:
            return String(localized: "Nickname")
        case .notes:
            return String(localized: "Notes")
        case .department:
            return String(localized: "Department")
        case .company:
            return String(localized: "Company")
        case .jobTitle:
            return String(localized: "Job Title")
        case .prefix:
            return String(localized: "Name Prefix")
        case .suffix:
            return String(localized: "Name Suffix")
        case .middleName:
            return String(localized: "Phonetic Middle Name")
        case .socialProfiles:
            return String(localized: "Social Profiles")
        case .instantMessageAddresses:
            return String(localized: "Instant Messaging Accounts")
        }
    }
}

let kWhitelistIdentifiersKey = "kWhitelistIdentifiersKey"
let kPhoneticFirstAndLastName = "kPhoneticFirstAndLastName"
let kQuickSearchKeyRawValue = "kQuickSearchKeyRawValueRawValue"
let kEnableNickname = "kEnableNickname"
let kEnableCustomName = "kEnableCustomName"
let kOverwriteAlreadyExists = "kOverwriteAlreadyExists"
let kAlwaysSeparatePinyin = "kAlwaysSeparatePinyin"
let kMassageCompanyKey = "kMassageCompanyKey"
let kEnableAllCleanPhonetic = "kEnableAllCleanPhonetic"
let kCleanPhoneticNickname = "kCleanPhoneticNickname"
let kCleanNotesKey = "kCleanNotesKey"
let kCleanPhoneticDepartment = "kCleanPhoneticDepartment"
let kCleanPhoneticCompany = "kCleanPhoneticCompany"
let kCleanPhoneticJobTitle = "kCleanPhoneticJobTitle"
let kCleanPhoneticPrefix = "kCleanPhoneticPrefix"
let kCleanPhoneticSuffix = "kCleanPhoneticSuffix"
let kCleanPhoneticMiddleName = "kCleanPhoneticMiddleName"
let kCleanSocialProfilesKeys = "kCleanSocialProfilesKeys"
let kCleanInstantMessageAddressesKeys = "kCleanInstantMessageAddressesKeys"

let kPhoneticFirstAndLastNameDefaultBool = true
let kEnableNicknameDefaultBool = true
let kEnableCustomNameDefaultBool = false
let kOverwriteAlreadyExistsDefaultBool = false
let kAlwaysSeparatePinyinDefaultBool = false
let kMassageCompanyKeyDefaultBool = false
let kEnableAllCleanPhoneticDefaultBool = false
let kCleanPhoneticNicknameDefaultBool = false
let kCleanNotesKeyDefaultBool = false
let kCleanPhoneticDepartmentDefaultBool = false
let kCleanPhoneticCompanyDefaultBool = false
let kCleanPhoneticJobTitleDefaultBool = false
let kCleanPhoneticMiddleNameDefaultBool = false
let kCleanPhoneticPrefixDefaultBool = false
let kCleanPhoneticSuffixDefaultBool = false
let kCleanSocialProfilesKeysDefaultBool = false
let kCleanInstantMessageKeysDefaultBool = false

let kUseTones = "kUseTones"
let kFixPolyphonicChar = "kFixPolyphonicChar"
let kUpcasePinyin = "kUpcasePinyin"
let kUseTonesDefaultBool = false
let kFixPolyphonicCharDefaultBool = true
let kUpcasePinyinDefaultBool = false
let displayedWalthroughKey = "DisplayedWalthroughKey"

var whitelistIdentifiers: NSArray {
    get { return UserDefaults.standard.array(forKey: kWhitelistIdentifiersKey) as NSArray? ?? NSArray() }
    set {
        guard let newId = newValue.firstObject else { return }
        let array = whitelistIdentifiers.mutableCopy() as! NSMutableArray
        array.contains(newId) ? array.remove(newId) : array.add(newId)
        UserDefaults.standard.set(array, forKey: kWhitelistIdentifiersKey)
    }
}
