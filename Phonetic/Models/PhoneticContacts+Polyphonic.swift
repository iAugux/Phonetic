// Created by Augus on 2/26/16
// Copyright © 2016 Augus <iAugux@gmail.com>

import Foundation

// MARK: - Fix polyphonic characters
extension PhoneticContacts {
    func manaullyFixPolyphonicCharacters(_ str: String) -> String {
        var tempString = str
        for element in PolyphonicChar.all {
            for spelling in element.spellings where tempString.contains(spelling) {
                guard element.isEnabled(in: userDefaults) else { break }
                tempString = tempString.replacingOccurrences(of: spelling, with: element.replacement)
            }
        }
        return tempString
    }
}
