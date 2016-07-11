//
//  UISwitch+Extension.swift
//
//  Created by Augus on 2/14/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


extension UISwitch {
    
    func shouldSwitch(_ userDefaultsKey: String, defaultBool: Bool) {
        var isOn: Bool
        if UserDefaults.standard.value(forKey: userDefaultsKey) == nil {
            isOn = defaultBool
        } else {
            isOn = UserDefaults.standard.bool(forKey: userDefaultsKey)
        }
        self.isOn = isOn
    }
    
    func shouldSwitch(_ userDefaults: UserDefaults, userDefaultsKey: String, defaultBool: Bool) {
        var isOn: Bool
        if userDefaults.value(forKey: userDefaultsKey) == nil {
            isOn = defaultBool
        } else {
            isOn = userDefaults.bool(forKey: userDefaultsKey)
        }
        self.isOn = isOn
    }
    
}
