// Created by Augus on 2/26/16
// Copyright © 2016 Augus <iAugux@gmail.com>

import Foundation

// MARK: - Fix polyphonic characters
extension PhoneticContacts {
    func manaullyFixPolyphonicCharacters(_ str: String) -> String {
        let surname = str.trimmingCharacters(in: .whitespacesAndNewlines)
        if surname.count > 1, let rule = PolyphonicChar.all.first(where: { $0.spellings.contains(surname) }) {
            // Check an exact compound surname before applying any single-character rules.
            return rule.isEnabled(in: userDefaults) ? str.replacingOccurrences(of: surname, with: rule.replacement) : str
        }

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
