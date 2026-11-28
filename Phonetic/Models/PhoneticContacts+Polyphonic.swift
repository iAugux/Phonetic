// Created by Augus on 2/26/16
// Copyright © 2016 Augus <iAugux@gmail.com>

import Foundation

// MARK: - Fix polyphonic characters
extension PhoneticContacts {
    private static let polyphonicRulesByFirstCharacter: [Character: [(spelling: String, rule: Polyphonic)]] = {
        var grouped: [Character: [(spelling: String, rule: Polyphonic)]] = [:]
        for rule in PolyphonicChar.all {
            for spelling in rule.spellings {
                guard let firstCharacter = spelling.first else { continue }
                grouped[firstCharacter, default: []].append((spelling, rule))
            }
        }
        // Match compound surnames before single-character rules that share a prefix.
        for key in grouped.keys {
            grouped[key]?.sort { $0.spelling.count > $1.spelling.count }
        }
        return grouped
    }()

    func manaullyFixPolyphonicCharacters(_ str: String) -> String {
        var result = ""
        result.reserveCapacity(str.utf8.count)
        var index = str.startIndex

        while index < str.endIndex {
            if let candidates = Self.polyphonicRulesByFirstCharacter[str[index]],
               let match = candidates.first(where: { str[index...].hasPrefix($0.spelling) }) {
                let nextIndex = str.index(index, offsetBy: match.spelling.count)
                if match.rule.isEnabled(in: userDefaults) {
                    result.append(match.rule.replacement)
                } else {
                    result.append(contentsOf: str[index..<nextIndex])
                }
                index = nextIndex
            } else {
                result.append(str[index])
                index = str.index(after: index)
            }
        }

        return result
    }
}
