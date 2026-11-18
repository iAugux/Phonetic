// Created by Augus on 2/26/16
// Copyright © 2016 Augus <iAugux@gmail.com>

import Foundation

// MARK: - Fix polyphonic characters
extension PhoneticContacts {
    func manaullyFixPolyphonicCharacters(_ str: String) -> String {
        var tempString = str
        for element in PolyphonicChar.all {
            if element.isEnabled(in: userDefaults), tempString.contains(element.character) {
                tempString = tempString.replacingOccurrences(of: element.character, with: element.replacement)
            }
        }
        return tempString
    }
}
