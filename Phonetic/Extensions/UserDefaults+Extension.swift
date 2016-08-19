//
//  NSUserDefaults+Extension.swift
//
//  Created by Augus on 2/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


extension UserDefaults {
    
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if value(forKey: key) == nil {
            set(defaultValue, forKey: key)
        }
        return bool(forKey: key)
    }
}

extension UserDefaults {
    
    func integer(forKey key: String, defaultValue: Int) -> Int {
        if value(forKey: key) == nil {
            set(defaultValue, forKey: key)
        }
        return integer(forKey: key)
    }
}

extension UserDefaults {
    
    func double(forKey key: String, defaultValue: Double) -> Double {
        if value(forKey: key) == nil {
            set(defaultValue, forKey: key)
        }
        return double(forKey: key)
    }
}

extension UserDefaults {
    
    func object(forKey key: String, defaultValue: AnyObject) -> Any? {
        if object(forKey: key) == nil {
            set(defaultValue, forKey: key)
        }
        return object(forKey: key)
    }
}


// MARK: -

extension UserDefaults {
    
    func color(forKey key: String) -> UIColor? {
        var color: UIColor?
        if let colorData = data(forKey: key) {
            color = NSKeyedUnarchiver.unarchiveObject(with: colorData) as? UIColor
        }
        return color
    }
    
    func setColor(_ color: UIColor?, forKey key: String) {
        var colorData: Data?
        if let color = color {
            colorData = NSKeyedArchiver.archivedData(withRootObject: color)
        }
        set(colorData, forKey: key)
    }
}

extension UserDefaults {
    
    func setArchivedData(_ object: AnyObject?, forKey key: String) {
        var data: Data?
        if let object = object {
            data = NSKeyedArchiver.archivedData(withRootObject: object)
        }
        set(data, forKey: key)
    }
    
    func unarchiveObjectWithData(forKey key: String) -> Any? {
        guard let object = object(forKey: key) else { return nil }
        guard let data = object as? Data else { return nil }
        return NSKeyedUnarchiver.unarchiveObject(with: data)
    }
}
