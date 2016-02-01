//
//  SettingViewController.swift
//  Phonetic
//
//  Created by Augus on 1/29/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


let kAddAccent         = "kAddAccent"
let kEnableAnimation   = "kEnableAnimation"
let kFixPolyphonicChar = "kFixPolyphonicChar"

let kAddAccentDefaultBool         = true
let kFixPolyphonicCharDefaultBool = true
let kEnableAnimationDefaultBool   = Device.size() == Size.Screen3_5Inch ? false : true //Device.isLargerThanScreenSize(Size.Screen3_5Inch) ? true : false

class SettingViewController: BaseViewController {
    
    private let userDefaults = NSUserDefaults.standardUserDefaults()

    @IBOutlet weak var enableAnimationSwitcher: UISwitch! {
        didSet {
            var isOn: Bool
            if userDefaults.valueForKey(kEnableAnimation) == nil {
                isOn = kEnableAnimationDefaultBool
            } else {
                isOn = userDefaults.boolForKey(kEnableAnimation)
            }
            enableAnimationSwitcher.on = isOn
        }
    }

    @IBOutlet weak var addAccentSwitcher: UISwitch! {
        didSet {
            var isOn: Bool
            if userDefaults.valueForKey(kAddAccent) == nil {
                isOn = kAddAccentDefaultBool
            } else {
                isOn = userDefaults.boolForKey(kAddAccent)
            }
            addAccentSwitcher.on = isOn
        }
    }
    
    @IBOutlet weak var fixPolyphonicCharSwitcher: UISwitch! {
        didSet {
            var isOn: Bool
            if userDefaults.valueForKey(kFixPolyphonicChar) == nil {
                isOn = kFixPolyphonicCharDefaultBool
            } else {
                isOn = userDefaults.boolForKey(kFixPolyphonicChar)
            }
            fixPolyphonicCharSwitcher.on = isOn
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        enableAnimationSwitcher.onTintColor   = GLOBAL_CUSTOM_COLOR
        addAccentSwitcher.onTintColor         = GLOBAL_CUSTOM_COLOR
        fixPolyphonicCharSwitcher.onTintColor = GLOBAL_CUSTOM_COLOR
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func enableAnimationSwitcherDidTap(sender: UISwitch) {
        if sender.on {
            userDefaults.setBool(true, forKey: kEnableAnimation)
        } else {
            userDefaults.setBool(false, forKey: kEnableAnimation)
        }
        userDefaults.synchronize()
    }
    
    @IBAction func addAccentSwitcherDidTap(sender: UISwitch) {
        if sender.on {
            userDefaults.setBool(true, forKey: kAddAccent)
        } else {
            userDefaults.setBool(false, forKey: kAddAccent)
        }
        userDefaults.synchronize()
    }
    
    @IBAction func fixPolyphonicCharSwitcherDidTap(sender: UISwitch) {
        if sender.on {
            userDefaults.setBool(true, forKey: kFixPolyphonicChar)
        } else {
            userDefaults.setBool(false, forKey: kFixPolyphonicChar)
        }
        userDefaults.synchronize()
    }
    

}
