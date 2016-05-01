//
//  NSUserDefaults+Extension.swift
//
//  Created by Augus on 2/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation


extension NSUserDefaults {
    
    func getBool(key: String, defaultKeyValue: Bool) -> Bool {
        return getBool(NSUserDefaults.standardUserDefaults(), key: key, defaultKeyValue: defaultKeyValue)
    }
    
    func getBool(userDefaults: NSUserDefaults, key: String, defaultKeyValue: Bool) -> Bool {
        if userDefaults.valueForKey(key) == nil {
            userDefaults.setBool(defaultKeyValue, forKey: key)
            userDefaults.synchronize()
        }
        return userDefaults.boolForKey(key)
    }
}

extension NSUserDefaults {
    
    func getInteger(key: String, defaultKeyValue: Int) -> Int {
       return getInteger(NSUserDefaults.standardUserDefaults(), key: key, defaultKeyValue: defaultKeyValue)
    }
    
    func getInteger(userDefaults: NSUserDefaults, key: String, defaultKeyValue: Int) -> Int {
        if userDefaults.valueForKey(key) == nil {
            userDefaults.setInteger(defaultKeyValue, forKey: key)
            userDefaults.synchronize()
        }
        return userDefaults.integerForKey(key)
    }
}

extension NSUserDefaults {
    
    func getDouble(key: String, defaultKeyValue: Double) -> Double {
        return getDouble(NSUserDefaults.standardUserDefaults(), key: key, defaultKeyValue: defaultKeyValue)
    }
    
    func getDouble(userDefaults: NSUserDefaults, key: String, defaultKeyValue: Double) -> Double {
        if userDefaults.valueForKey(key) == nil {
            userDefaults.setDouble(defaultKeyValue, forKey: key)
            userDefaults.synchronize()
        }
        return userDefaults.doubleForKey(key)
    }
}

extension NSUserDefaults {
    
    func getObject(key: String, defaultkeyValue: AnyObject) -> AnyObject? {
        return getObject(NSUserDefaults.standardUserDefaults(), key: key, defaultkeyValue: defaultkeyValue)
    }
    
    func getObject(userDefaults: NSUserDefaults, key: String, defaultkeyValue: AnyObject) -> AnyObject? {
        if userDefaults.objectForKey(key) == nil {
            userDefaults.setObject(defaultkeyValue, forKey: key)
            userDefaults.synchronize()
        }
        return userDefaults.objectForKey(key)
    }
}