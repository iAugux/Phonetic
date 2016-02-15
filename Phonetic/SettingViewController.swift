//
//  SettingViewController.swift
//  Phonetic
//
//  Created by Augus on 1/29/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


let kUseTones                     = "kUseTones"
let kEnableAnimation              = "kEnableAnimation"
let kFixPolyphonicChar            = "kFixPolyphonicChar"
let kUpcasePinyin                 = "kUpcasePinyin"

let kUseTonesDefaultBool          = false
let kFixPolyphonicCharDefaultBool = true
let kUpcasePinyinDefaultBool      = false
let kEnableAnimationDefaultBool   = Device.size() == Size.Screen3_5Inch ? false : true

class SettingViewController: BaseViewController {
    
    private var customBarButton: UIButton!
    private let userDefaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet weak var enableAnimationSwitch: UISwitch! {
        didSet {
            enableAnimationSwitch.shouldSwitch(kEnableAnimation, defaultBool: kEnableAnimationDefaultBool)
        }
    }
    
    @IBOutlet weak var useTonesSwitch: UISwitch! {
        didSet {
            useTonesSwitch.shouldSwitch(kUseTones, defaultBool: kUseTonesDefaultBool)
        }
    }
    
    @IBOutlet weak var fixPolyphonicCharSwitch: UISwitch! {
        didSet {
            fixPolyphonicCharSwitch.shouldSwitch(kFixPolyphonicChar, defaultBool: kFixPolyphonicCharDefaultBool)
        }
    }
    
    @IBOutlet weak var upcasePinyinSwitch: UISwitch! {
        didSet {
            upcasePinyinSwitch.shouldSwitch(kUpcasePinyin, defaultBool: kUpcasePinyinDefaultBool)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        enableAnimationSwitch.onTintColor   = GLOBAL_CUSTOM_COLOR
        useTonesSwitch.onTintColor          = GLOBAL_CUSTOM_COLOR
        fixPolyphonicCharSwitch.onTintColor = GLOBAL_CUSTOM_COLOR
        upcasePinyinSwitch.onTintColor      = GLOBAL_CUSTOM_COLOR
        
        configureCustomBarButtonItem()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func configureCustomBarButtonItem() {
        guard let navBar = navigationController?.navigationBar else { return }
        
        customBarButton = UIButton(type: .Custom)
        customBarButton.frame = CGRectMake(0, 0, 25, 25)
        customBarButton.tintColor = UIColor.whiteColor()
        customBarButton.setImage(UIImage(named: "additional_settings")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        customBarButton.center = navBar.center
        customBarButton.frame.origin.x = 13.0
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
    
    // MARKS: - Actions of UISwitch
    @IBAction func enableAnimationSwitchDidTap(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: kEnableAnimation)
        userDefaults.synchronize()
    }
    
    @IBAction func useTonesSwitchDidTap(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: kUseTones)
        userDefaults.synchronize()
    }
    
    @IBAction func fixPolyphonicCharSwitchDidTap(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: kFixPolyphonicChar)
        userDefaults.synchronize()
    }
    
    @IBAction func upcasePinyinSwitchDidTap(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: kUpcasePinyin)
        userDefaults.synchronize()
    }
    
}
