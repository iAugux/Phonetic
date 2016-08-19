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
        if let langCode = Locale.preferredLanguages.first {
            return isChineseLanguage(langCode)
        }
        return false
    }
    
    // ["zh-Hant-US", "en-US", "zh-Hans-US", "zh-HK", "zh-TW"]
    fileprivate static func isChineseLanguage(_ id: String) -> Bool {
        
        guard !id.contains("zh-Hans") else { return true } // Chinese Mandrain
        guard !id.contains("zh-TW")   else { return true } // Taiwan
        guard !id.contains("zh-HK")   else { return true } // HongKong
        guard !id.contains("zh-Hant") else { return true } // HongKong
        
        return false
    }
    
}
