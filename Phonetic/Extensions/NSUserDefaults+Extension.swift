//
//  NSUserDefaults+Extension.swift
//
//  Created by Augus on 2/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation


extension NSUserDefaults {
    
    func getBool(key: String, defaultKeyValue: Bool) -> Bool {
        if NSUserDefaults.standardUserDefaults().valueForKey(key) == nil {
            NSUserDefaults.standardUserDefaults().setBool(defaultKeyValue, forKey: key)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        return NSUserDefaults.standardUserDefaults().boolForKey(key)
    }
    
    func getBool(userDefaults: NSUserDefaults, key: String, defaultKeyValue: Bool) -> Bool {
        if userDefaults.valueForKey(key) == nil {
            userDefaults.setBool(defaultKeyValue, forKey: key)
            userDefaults.synchronize()
        }
        return userDefaults.boolForKey(key)
    }

    
}