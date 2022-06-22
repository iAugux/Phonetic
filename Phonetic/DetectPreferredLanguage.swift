//
//  DetectPreferredLanguage.swift
//  Phonetic
//
//  Created by Augus on 2/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation

struct DetectPreferredLanguage {
    static var isChineseLanguage: Bool {
        guard let langCode = Locale.preferredLanguages.first else { return false }
        return isChineseLanguage(langCode)
    }

    static var isSimplifiedChinese: Bool {
        guard let langCode = Locale.preferredLanguages.first else { return false }
        return langCode.contains("zh-Hans")
    }

    // ["zh-Hant-US", "en-US", "zh-Hans-US", "zh-HK", "zh-TW"]
    private static func isChineseLanguage(_ id: String) -> Bool {
        guard !id.contains("zh-Hans") else { return true } // Chinese Mandrain
        guard !id.contains("zh-TW") else { return true } // Taiwan
        guard !id.contains("zh-HK") else { return true } // HongKong
        guard !id.contains("zh-Hant") else { return true } // HongKong
        return false
    }
}

// MARK: -
let kAppleLanguages = "AppleLanguages"

enum CustomLanguage: Int {
    case auto
    case en
    case sc
    case tc
    case cancel

    var langs: [String]? {
        switch self {
        case .auto: return nil
        case .en: return ["en"]
        case .sc: return ["zh-Hans"]
        case .tc: return ["zh-HK"]
        case .cancel: return []
        }
    }

    var description: String {
        switch self {
        case .auto: return NSLocalizedString("Automatic", comment: "")
        case .en: return NSLocalizedString("English", comment: "")
        case .sc: return NSLocalizedString("Simplified Chinese", comment: "")
        case .tc: return NSLocalizedString("Traditional Chinese", comment: "")
        case .cancel: return NSLocalizedString("Cancel", comment: "")
        }
    }
}
