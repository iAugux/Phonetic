// Created by Augus on 2/15/16
// Copyright © 2016 Augus <iAugux@gmail.com>

import Foundation

enum DetectPreferredLanguage {
    static var isChineseLanguage: Bool {
        guard let langCode = Locale.preferredLanguages.first else { return false }
        return isChineseLanguage(langCode)
    }

    /// ["zh-Hant-US", "en-US", "zh-Hans-US", "zh-HK", "zh-TW"]
    private static func isChineseLanguage(_ id: String) -> Bool {
        guard !id.contains("zh-Hans") else { return true } // Chinese Mandrain
        guard !id.contains("zh-TW") else { return true } // Taiwan
        guard !id.contains("zh-HK") else { return true } // HongKong
        guard !id.contains("zh-Hant") else { return true } // HongKong
        return false
    }
}
