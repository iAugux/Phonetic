// Created by Augus on 2021/10/1
// Copyright © 2021 Augus <iAugux@gmail.com>

import UIKit

extension UISwitch {
    /// Switch by given user defaults key.
    ///
    /// - Parameters:
    ///   - userDefaults: Custom user default, using `UserDefault.standard` if not set.
    ///   - userDefaultsKey: the user default key
    ///   - default: default value for this Switch, true or false.
    /// - Returns: Returns the switch's status, on or off
    @discardableResult
    func shouldSwitch(using userDefaults: UserDefaults? = nil, for userDefaultsKey: String, default: Bool, animated: Bool = false) -> Bool {
        let defaults = userDefaults ?? UserDefaults.standard
        let isOn = defaults.value(forKey: userDefaultsKey) == nil ? `default` : defaults.bool(forKey: userDefaultsKey)
        setOn(isOn, animated: animated)
        return isOn
    }
}
