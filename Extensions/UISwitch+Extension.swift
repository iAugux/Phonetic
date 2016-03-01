//
//  UISwitch+Extension.swift
//
//  Created by Augus on 2/14/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


extension UISwitch {
    
    func shouldSwitch(userDefaultsKey: String, defaultBool: Bool) {
        var isOn: Bool
        if NSUserDefaults.standardUserDefaults().valueForKey(userDefaultsKey) == nil {
            isOn = defaultBool
        } else {
            isOn = NSUserDefaults.standardUserDefaults().boolForKey(userDefaultsKey)
        }
        self.on = isOn
    }
    
    func shouldSwitch(userDefaults: NSUserDefaults, userDefaultsKey: String, defaultBool: Bool) {
        var isOn: Bool
        if userDefaults.valueForKey(userDefaultsKey) == nil {
            isOn = defaultBool
        } else {
            isOn = userDefaults.boolForKey(userDefaultsKey)
        }
        self.on = isOn
    }
    
}