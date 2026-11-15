// Created by Augus on 6/12/24
// Copyright © 2024 Augus <iAugux@gmail.com>

import Foundation

typealias Closure = () -> Void

extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if object(forKey: key) == nil {
            set(defaultValue, forKey: key)
        }
        return bool(forKey: key)
    }
}
