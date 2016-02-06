//
//  SettingViewController.swift
//  Phonetic
//
//  Created by Augus on 1/29/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


let kUseTones          = "kUseTones"
let kEnableAnimation   = "kEnableAnimation"
let kFixPolyphonicChar = "kFixPolyphonicChar"
let kUpcasePinyin      = "kUpcasePinyin"

let kAddAccentDefaultBool         = true
let kFixPolyphonicCharDefaultBool = true
let kUpcasePinyinDefaultBool      = false
let kEnableAnimationDefaultBool   = Device.size() == Size.Screen3_5Inch ? false : true

class SettingViewController: BaseViewController {
    
    private var customBarButton: UIButton!
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
    
    @IBOutlet weak var useTonesSwitcher: UISwitch! {
        didSet {
            var isOn: Bool
            if userDefaults.valueForKey(kUseTones) == nil {
                isOn = kAddAccentDefaultBool
            } else {
                isOn = userDefaults.boolForKey(kUseTones)
            }
            useTonesSwitcher.on = isOn
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
    
    @IBOutlet weak var upcasePinyinSwitcher: UISwitch! {
        didSet {
            var isOn: Bool
            if userDefaults.valueForKey(kUpcasePinyin) == nil {
                isOn = kUpcasePinyinDefaultBool
            } else {
                isOn = userDefaults.boolForKey(kUpcasePinyin)
            }
            upcasePinyinSwitcher.on = isOn
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        enableAnimationSwitcher.onTintColor   = GLOBAL_CUSTOM_COLOR
        useTonesSwitcher.onTintColor          = GLOBAL_CUSTOM_COLOR
        fixPolyphonicCharSwitcher.onTintColor = GLOBAL_CUSTOM_COLOR
        upcasePinyinSwitcher.onTintColor      = GLOBAL_CUSTOM_COLOR
        
        configureCustomBarButtonItem()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func configureCustomBarButtonItem() {
        guard let navBar = navigationController?.navigationBar else { return }
        
        customBarButton = UIButton(type: .Custom)
        customBarButton.frame = CGRectMake(0, 0, 33, navBar.frame.height)
        customBarButton.tintColor = UIColor.whiteColor()
        customBarButton.setImage(UIImage(named: "more")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        customBarButton.center = navBar.center
        customBarButton.frame.origin.x = 12.0
        customBarButton.addTarget(self, action: "customBarButtonDidTap", forControlEvents: .TouchUpInside)
        navBar.addSubview(customBarButton)
    }
    
    func customBarButtonDidTap() {
                
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            presentPopoverController()
        } else {
            // dismiss current view controller first.
            dismissViewControllerAnimated(true) { () -> Void in
                self.presentPopoverController()
            }
        }
    }
    
    private func presentPopoverController() {
        guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("AdditionalSettingsNavigationController") as? UINavigationController else { return }
        
        vc.modalPresentationStyle = .Popover
        vc.popoverPresentationController?.canOverlapSourceViewRect = true
        vc.popoverPresentationController?.sourceView = customBarButton
        UIApplication.topMostViewController()?.presentViewController(vc, animated: true, completion: nil)
    }
    
    // MARKS: - actions of UISwitch
    @IBAction func enableAnimationSwitcherDidTap(sender: UISwitch) {
        if sender.on {
            userDefaults.setBool(true, forKey: kEnableAnimation)
        } else {
            userDefaults.setBool(false, forKey: kEnableAnimation)
        }
        userDefaults.synchronize()
    }
    
    @IBAction func useTonesSwitcherDidTap(sender: UISwitch) {
        if sender.on {
            userDefaults.setBool(true, forKey: kUseTones)
        } else {
            userDefaults.setBool(false, forKey: kUseTones)
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
    
    @IBAction func upcasePinyinSwitcherDidTap(sender: UISwitch) {
        if sender.on {
            userDefaults.setBool(true, forKey: kUpcasePinyin)
        } else {
            userDefaults.setBool(false, forKey: kUpcasePinyin)
        }
        userDefaults.synchronize()
    }
    
}
