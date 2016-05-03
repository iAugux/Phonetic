//
//  NSUserDefaults+Extension.swift
//
//  Created by Augus on 2/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation


extension NSUserDefaults {
    
    func getBool(key: String, defaultKeyValue: Bool) -> Bool {
        if valueForKey(key) == nil {
            setBool(defaultKeyValue, forKey: key)
            synchronize()
        }
        return boolForKey(key)
    }
}

extension NSUserDefaults {
    
    func getInteger(key: String, defaultKeyValue: Int) -> Int {
        if valueForKey(key) == nil {
            setInteger(defaultKeyValue, forKey: key)
            synchronize()
        }
        return integerForKey(key)
    }
}

extension NSUserDefaults {
    
    func getDouble(key: String, defaultKeyValue: Double) -> Double {
        if valueForKey(key) == nil {
            setDouble(defaultKeyValue, forKey: key)
            synchronize()
        }
        return doubleForKey(key)
    }
}

extension NSUserDefaults {
    
    func getObject(key: String, defaultkeyValue: AnyObject) -> AnyObject? {
        if objectForKey(key) == nil {
            setObject(defaultkeyValue, forKey: key)
            synchronize()
        }
        return objectForKey(key)
    }
}