//
//  UserDefaults+Extension.swift
//
//  Created by Augus on 2/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation


extension UserDefaults {
    
    func getBool(_ key: String, defaultKeyValue: Bool) -> Bool {
        if value(forKey: key) == nil {
            set(defaultKeyValue, forKey: key)
            synchronize()
        }
        return bool(forKey: key)
    }
}

extension UserDefaults {
    
    func getInteger(_ key: String, defaultKeyValue: Int) -> Int {
        if value(forKey: key) == nil {
            set(defaultKeyValue, forKey: key)
            synchronize()
        }
        return integer(forKey: key)
    }
}

extension UserDefaults {
    
    func getDouble(_ key: String, defaultKeyValue: Double) -> Double {
        if value(forKey: key) == nil {
            set(defaultKeyValue, forKey: key)
            synchronize()
        }
        return double(forKey: key)
    }
}

extension UserDefaults {
    
    func getObject(_ key: String, defaultkeyValue: AnyObject) -> AnyObject? {
        if object(forKey: key) == nil {
            set(defaultkeyValue, forKey: key)
            synchronize()
        }
        return object(forKey: key)
    }
}
