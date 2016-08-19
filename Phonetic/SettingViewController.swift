//
//  SettingViewController.swift
//  Phonetic
//
//  Created by Augus on 1/29/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit
import Device


let kUseTones                     = "kUseTones"
let kEnableAnimation              = "kEnableAnimation"
let kFixPolyphonicChar            = "kFixPolyphonicChar"
let kUpcasePinyin                 = "kUpcasePinyin"

let kUseTonesDefaultBool          = false
let kFixPolyphonicCharDefaultBool = true
let kUpcasePinyinDefaultBool      = false
let kEnableAnimationDefaultBool   = Device.size() == Size.screen3_5Inch ? false : true

let kVCWillDisappearNotification  = "kVCWillDisappearNotification"

var kShouldRepresentAdditionalVC  = false
var kShouldRepresentPolyphonicVC  = false

class SettingViewController: UIViewController {
    
    @IBOutlet weak var polyphonicButton: UIButton!
    
    fileprivate let userDefaults = UserDefaults.standard
    
    fileprivate var customBarButton: UIButton!
    
    
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: Notification.Name(rawValue: kVCWillDisappearNotification), object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "VCPresentPolyphonicVC" {
            guard let destinationVC = segue.destination as? SettingsNavigationController else { return }
            destinationVC.popoverPresentationController?.sourceRect = polyphonicButton.bounds
            destinationVC.popoverPresentationController?.backgroundColor = kNavigationBarBackgroundColor
        }
    }
    
    private func configureCustomBarButtonItem() {
        guard let navBar = navigationController?.navigationBar else { return }
        
        customBarButton = UIButton(type: .custom)
        customBarButton.tintColor = UIColor.white
        customBarButton.setImage(UIImage(named: "additional_settings")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
        customBarButton.addTarget(self, action: #selector(customBarButtonDidTap), for: .touchUpInside)
        navBar.addSubview(customBarButton)
        customBarButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(25)
            make.centerY.equalTo(navBar)
            make.left.equalTo(13)
        }
    }
    
    @objc private func customBarButtonDidTap() {
                
        if UIDevice.isPad {
            presentPopoverController()
            kShouldRepresentAdditionalVC = true
        } else {
            // dismiss current view controller first.
            dismiss(animated: true) { () -> Void in
                self.presentPopoverController()
            }
        }
    }
    
    private func presentPopoverController() {
        guard let vc = UIStoryboard.Main.instantiateViewController(withIdentifier: String(describing: SettingsNavigationController.self)) as? SettingsNavigationController,
            let sourceView = customBarButton else { return }
        
        vc.modalPresentationStyle = .popover
        vc.popoverPresentationController?.canOverlapSourceViewRect = true
        vc.popoverPresentationController?.sourceView = sourceView
        vc.popoverPresentationController?.sourceRect = sourceView.bounds
        vc.popoverPresentationController?.backgroundColor = kNavigationBarBackgroundColor
        
        UIApplication.topMostViewController?.present(vc, animated: true, completion:nil)
    }
    
    // MARKS: - Actions of UISwitch
    @IBAction func enableAnimationSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kEnableAnimation)
        userDefaults.synchronize()
    }
    
    @IBAction func useTonesSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kUseTones)
        userDefaults.synchronize()
    }
    
    @IBAction func fixPolyphonicCharSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kFixPolyphonicChar)
        userDefaults.synchronize()
    }
    
    @IBAction func upcasePinyinSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kUpcasePinyin)
        userDefaults.synchronize()
    }
    
}


extension SettingViewController {
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        
        guard UIDevice.isPad else { return }
       
        _ = kShouldRepresentAdditionalVC ? customBarButton?.sendActions(for: .touchUpInside) : ()
        _ = kShouldRepresentPolyphonicVC ? polyphonicButton?.sendActions(for: .touchUpInside) : ()
    }
}

