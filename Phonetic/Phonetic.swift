//
//  Phonetic.swift
//  Phonetic
//
//  Created by Augus on 2/6/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Contacts

let kPhoneticFirstAndLastName         = "kPhoneticFirstAndLastName"

let kQuickSearchKeyRawValue           = "kQuickSearchKeyRawValueRawValue"
let kAdditionalSettingsStatus         = "kAdditionalSettingsStatus"
let kEnableNickname                   = "kEnableNickname"
let kEnableCustomName                 = "kEnableCustomName"
let kOverwriteAlreadyExists           = "kOverwriteAlreadyExists"
let kKeepSettingsWindowOpen           = "kKeepSettingsWindowOpen"
let kForceEnableAnimation             = "kForceEnableAnimation"
let kAlwaysSeparatePinyin             = "kAlwaysSeparatePinyin"

let kEnableAllCleanPhonetic           = "kEnableAllCleanPhonetic"
let kCleanPhoneticNickname            = "kCleanPhoneticNickname"
let kCleanPhoneticMiddleName          = "kCleanPhoneticMiddleName"
let kCleanPhoneticDepartment          = "kCleanPhoneticDepartment"
let kCleanPhoneticCompany             = "kCleanPhoneticCompany"
let kCleanPhoneticJobTitle            = "kCleanPhoneticJobTitle"
let kCleanPhoneticPrefix              = "kCleanPhoneticPrefix"
let kCleanPhoneticSuffix              = "kCleanPhoneticSuffix"
let kCleanSocialProfilesKeys          = "kCleanSocialProfilesKeys"
let kCleanInstantMessageAddressesKeys = "kCleanInstantMessageAddressesKeys"


let kPhoneticFirstAndLastNameDefaultBool = true

let kAdditionalSettingsStatusDefaultBool = true
let kEnableNicknameDefaultBool           = true
let kEnableCustomNameDefaultBool         = false
let kOverwriteAlreadyExistsDefaultBool   = false
let kKeepSettingsWindowOpenDefaultBool   = false
let kForceEnableAnimationDefaultBool     = false
let kAlwaysSeparatePinyinDefaultBool     = false

let kEnableAllCleanPhoneticDefaultBool   = false
let kCleanPhoneticNicknameDefaultBool    = false
let kCleanPhoneticMiddleNameDefaultBool  = false
let kCleanPhoneticDepartmentDefaultBool  = false
let kCleanPhoneticCompanyDefaultBool     = false
let kCleanPhoneticJobTitleDefaultBool    = false
let kCleanPhoneticPrefixDefaultBool      = false
let kCleanPhoneticSuffixDefaultBool      = false
let kCleanSocialProfilesKeysDefaultBool  = false
let kCleanInstantMessageKeysDefaultBool  = false

struct Phonetic {
    var brief: String
    var value: String
}

enum QuickSearch: Int {
    case middleName
    case department
    case company
    case jobTitle
    case prefix
    case suffix
    case cancel
    
    var key: String {
        switch self {
        case .middleName:
            return NSLocalizedString("Middle Name", comment: "")
        case .department:
            return NSLocalizedString("Department", comment: "")
        case .company:
            return NSLocalizedString("Company", comment: "")
        case .jobTitle:
            return NSLocalizedString("Job Title", comment: "")
        case .prefix:
            return NSLocalizedString("Prefix", comment: "")
        case .suffix:
            return NSLocalizedString("Suffix", comment: "")
        case .cancel:
            return NSLocalizedString("Cancel", comment: "")
        }
    }
}

enum PhoneticKeys: String {
    case nickname
    case middleName
    case department
    case company
    case jobTitle
    case prefix
    case suffix
    case socialProfiles
    case instantMessageAddresses
    
    var key: String {
        switch self {
        case .nickname:
            return NSLocalizedString("Nickname", comment: "")
        case .middleName:
            return NSLocalizedString("Middle Name", comment: "")
        case .department:
            return NSLocalizedString("Department", comment: "")
        case .company:
            return NSLocalizedString("Company", comment: "")
        case .jobTitle:
            return NSLocalizedString("Job Title", comment: "")
        case .prefix:
            return NSLocalizedString("Prefix", comment: "")
        case .suffix:
            return NSLocalizedString("Suffix", comment: "")
        case .socialProfiles:
            return NSLocalizedString("Social Profiles", comment: "")
        case .instantMessageAddresses:
            return NSLocalizedString("Instant Message Addresses", comment: "")
        }
    }
}
