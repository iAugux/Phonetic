//
//  AdditionalSettingsViewController.swift
//  Phonetic
//
//  Created by Augus on 2/3/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


let kAdditionalSettingsStatus            = "kAdditionalSettingsStatus"
let kEnableMiddleName                    = "kEnableMiddleName"
let kOverwriteMiddleName                 = "kOverwriteMiddleName"
let kKeepSettingsWindowOpen              = "kKeepSettingsWindowOpen"
let kForceEnableAnimation                = "kForceEnableAnimation"

let kAdditionalSettingsStatusDefaultBool = true
let kEnableMiddleNameDefaultBool         = true
let kOverwriteMiddleNameDefaultBool      = false
let kKeepSettingsWindowOpenDefaultBool   = false
let kForceEnableAnimationDefaultBool     = false

let kDismissedAdditionalSettingsVCNotification = "kDismissedAdditionalSettingsVCNotification"

let SWITCH_TINT_COLOR_FOR_UI_SETTINGS = UIColor(red: 0.4395, green: 0.8138, blue: 0.9971, alpha: 1.0)

class AdditionalSettingsViewController: UITableViewController {
    
    private let userDefaults = NSUserDefaults.standardUserDefaults()
    
    private let on           = NSLocalizedString("On", comment: "")
    private let off          = NSLocalizedString("Off", comment: "")
    private let _title       = NSLocalizedString("Additional Settings", comment: "UINavigationController title - Additional Settings")
    
    private let _color       = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
    private let _font        = UIFont.systemFontOfSize(17.0)
    private let _textColor   = UIColor.whiteColor()

    private var blurBackgroundView: BlurImageView!
    private var leftBarButtonItem: UIBarButtonItem!
    private var customBarButton: UIButton!
    private var customTitleLabel: UILabel!
    private var customStatusBar: UIView!
    
    private var shouldHideCustomBarButton: Bool {
        // iPad
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            return true
        }
        
        // 6(s) Plus or larger iPhones in the future (maybe).
        if Device.isLargerThanScreenSize(Size.Screen4_7Inch) {
            return UIDevice.currentDevice().orientation.isLandscape
        }
        
        return false
    }
    
    private var hideCustomBarButton = false {
        didSet {
            if !hideCustomBarButton {
                customBarButton?.hidden = false
            } else {
                customBarButton?.hidden = true
            }
        }
    }
    
    // MARK: - Deinit
    deinit {
        tableView.dg_removePullToRefresh()
    }
    
    // MARK: - UISwitch
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var statusSwitch: UISwitch! {
        didSet {
            var isOn: Bool
            if userDefaults.valueForKey(kAdditionalSettingsStatus) == nil {
                isOn = kAdditionalSettingsStatusDefaultBool
            } else {
                isOn = userDefaults.boolForKey(kAdditionalSettingsStatus)
            }
            statusSwitch.on = isOn
        }
    }

    @IBOutlet weak var nicknameSwitch: UISwitch! {
        didSet {
            var isOn: Bool
            if userDefaults.valueForKey(kEnableMiddleName) == nil {
                isOn = kEnableMiddleNameDefaultBool
            } else {
                isOn = userDefaults.boolForKey(kEnableMiddleName)
            }
            nicknameSwitch.on = isOn
        }
    }

    @IBOutlet weak var overwriteMiddleNameSwitch: UISwitch! {
        didSet {
            var isOn: Bool
            if userDefaults.valueForKey(kOverwriteMiddleName) == nil {
                isOn = kOverwriteMiddleNameDefaultBool
            } else {
                isOn = userDefaults.boolForKey(kOverwriteMiddleName)
            }
            overwriteMiddleNameSwitch.on = isOn
        }
    }
    
    @IBOutlet weak var forceOpenAnimationSwitch: UISwitch! {
        didSet {
            var isOn: Bool
            if userDefaults.valueForKey(kForceEnableAnimation) == nil {
                isOn = kForceEnableAnimationDefaultBool
            } else {
                isOn = userDefaults.boolForKey(kForceEnableAnimation)
            }
            forceOpenAnimationSwitch.on = isOn
        }
    }
    
    @IBOutlet weak var keepSettingWindowOpenSwitch: UISwitch! {
        didSet {
            var isOn: Bool
            if userDefaults.valueForKey(kKeepSettingsWindowOpen) == nil {
                isOn = kKeepSettingsWindowOpenDefaultBool
            } else {
                isOn = userDefaults.boolForKey(kKeepSettingsWindowOpen)
            }
            keepSettingWindowOpenSwitch.on = isOn
        }
    }
    
    private var keepSettingWindowOpen: Bool {
        if userDefaults.valueForKey(kKeepSettingsWindowOpen) == nil {
            userDefaults.setBool(kKeepSettingsWindowOpenDefaultBool, forKey: kKeepSettingsWindowOpen)
            userDefaults.synchronize()
        }
        return userDefaults.boolForKey(kKeepSettingsWindowOpen)
    }
    
}

// MARK: - Life Cycle
extension AdditionalSettingsViewController {

    override func loadView() {
        super.loadView()
        navigationController?.completelyTransparentBar()
        navigationController?.navigationBar.backgroundColor = _color
        
        configureCustomStatusBar()
        configureCustomBarButton()
        configureCustomTitleLabel()
        
        statusLabel.text                        = statusSwitch.on ? on : off
        statusSwitch.onTintColor                = GLOBAL_CUSTOM_COLOR
        nicknameSwitch.onTintColor              = GLOBAL_CUSTOM_COLOR
        overwriteMiddleNameSwitch.onTintColor   = GLOBAL_CUSTOM_COLOR
        
        forceOpenAnimationSwitch.onTintColor    = SWITCH_TINT_COLOR_FOR_UI_SETTINGS
        keepSettingWindowOpenSwitch.onTintColor = SWITCH_TINT_COLOR_FOR_UI_SETTINGS
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        blurBackgroundView = BlurImageView(frame: view.bounds)
        tableView.backgroundView = blurBackgroundView
        tableView.separatorColor = UIColor(red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0)

        configurePullToDismissViewController(UIColor.clearColor(), fillColor: _color, completionHandler: {
            self.postDismissedNotificationIfNeeded()
        })
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        blurBackgroundView?.layoutIfNeeded()
        fixCustomTitleLabelPosition()
        fixCustomBarButtonPosition()
        hideCustomStatusBarIfNeeded()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
}

// MARK: - Actions of UISwitch
extension AdditionalSettingsViewController {
    
    @IBAction func statusSwitchDidTap(sender: UISwitch) {
        
        statusLabel.text = sender.on ? on : off

        nicknameSwitch.enabled = sender.on
        overwriteMiddleNameSwitch.enabled = sender.on
        
        if sender.on {
            userDefaults.setBool(true, forKey: kAdditionalSettingsStatus)
        } else {
            userDefaults.setBool(false, forKey: kAdditionalSettingsStatus)
        }
        userDefaults.synchronize()
    }
    
    @IBAction func nicknameSwitchDidTap(sender: UISwitch) {
        if sender.on {
            userDefaults.setBool(true, forKey: kEnableMiddleName)
            
            // enable `OverwriteMiddleNameSwitch` if needed
            if overwriteMiddleNameSwitch.on {
                overwriteMiddleNameSwitch.enabled = true
            }
            
        } else {
            userDefaults.setBool(false, forKey: kEnableMiddleName)
            
            // disable `OverwriteMiddleNameSwitch` if needed
            if overwriteMiddleNameSwitch.on {
                overwriteMiddleNameSwitch.enabled = false
            }
        }
        userDefaults.synchronize()
    }
    
    @IBAction func overwriteMiddleNameSwitchDidTap(sender: UISwitch) {
        if sender.on {
            userDefaults.setBool(true, forKey: kOverwriteMiddleName)
            
            // Turn on `MiddleNameSwitch` with delay.
            NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "turnOnMiddleNameSwitchAutomatically", userInfo: nil, repeats: false)
            
        } else {
            userDefaults.setBool(false, forKey: kOverwriteMiddleName)
        }
        userDefaults.synchronize()
    }
    
    @IBAction func forceOpenAnimationSwitchDidTap(sender: UISwitch) {
        if sender.on {
            userDefaults.setBool(true, forKey: kForceEnableAnimation)
        } else {
            userDefaults.setBool(false, forKey: kForceEnableAnimation)
        }
        userDefaults.synchronize()
    }
    
    @IBAction func keepSettingWindowOpenSwitchDidTap(sender: UISwitch) {
        if sender.on {
            userDefaults.setBool(true, forKey: kKeepSettingsWindowOpen)
        } else {
            userDefaults.setBool(false, forKey: kKeepSettingsWindowOpen)
        }
        userDefaults.synchronize()
    }

    internal func turnOnMiddleNameSwitchAutomatically() {
        if let _ = nicknameSwitch?.setOn(true, animated: true) {
            userDefaults.setBool(true, forKey: kEnableMiddleName)
        }
    }
    
}

// MARK: - Configure Subviews
extension AdditionalSettingsViewController {
    
    private func hideCustomStatusBarIfNeeded() {
        guard UIDevice.currentDevice().userInterfaceIdiom != .Pad else { return }
        
        if UIDevice.currentDevice().orientation.isPortrait {
            customStatusBar?.frame = UIApplication.sharedApplication().statusBarFrame
            customStatusBar?.hidden = false
        } else {
            customStatusBar?.hidden = true
        }
    }
    
    private func configureCustomStatusBar() {
        
        guard UIDevice.currentDevice().userInterfaceIdiom != .Pad else {
            return
        }
        
        customStatusBar = UIView(frame: UIApplication.sharedApplication().statusBarFrame)
        customStatusBar.backgroundColor = _color
        
        UIApplication.topMostViewController()?.view.addSubview(customStatusBar)
    }
    
    private func configureCustomBarButton() {
        customBarButton = UIButton(type: .Custom)
        customBarButton.setImage(UIImage(named: "close")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        customBarButton.tintColor   = UIColor.whiteColor()
        customBarButton.frame.size  = CGSizeMake(50, 50)
        customBarButton.contentMode = .Center
        customBarButton.addTarget(self, action: "dismissViewController", forControlEvents: .TouchUpInside)

        navigationController?.navigationBar.addSubview(customBarButton)

        hideCustomBarButton = shouldHideCustomBarButton
    }
    
    private func fixCustomBarButtonPosition() {
        
        if let navigationBar = navigationController?.navigationBar {
            customBarButton?.center = navigationBar.center
            customBarButton?.frame.origin.x = 8.0
            
            if UIDevice.currentDevice().orientation.isPortrait {
                customBarButton?.frame.origin.y -= UIApplication.sharedApplication().statusBarFrame.height
            }
        }
    }
    
    private func configureCustomTitleLabel() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        
        customTitleLabel               = UILabel(frame: CGRectZero)
        customTitleLabel.textAlignment = .Center
        customTitleLabel.textColor     = _textColor
        customTitleLabel.font          = _font
        customTitleLabel.text          = _title
        customTitleLabel.sizeToFit()
        
        navigationBar.addSubview(customTitleLabel)
    }
    
    private func fixCustomTitleLabelPosition() {
        
        if let navigationBar = navigationController?.navigationBar {
            customTitleLabel?.center = navigationBar.center
            
            if UIDevice.currentDevice().orientation.isPortrait && UIDevice.currentDevice().userInterfaceIdiom != .Pad {
                customTitleLabel?.frame.origin.y -= UIApplication.sharedApplication().statusBarFrame.height
            }
        }
    }
}

// MARK: - Keep `SettingViewController` open after dismissing.
extension AdditionalSettingsViewController {

    private func postDismissedNotificationIfNeeded() {
        // It is not necessary here, but I prefer to keep it.
        guard UIDevice.currentDevice().userInterfaceIdiom != .Pad else { return }
        
        guard keepSettingWindowOpen else { return }
        
        NSNotificationCenter.defaultCenter().postNotificationName(kDismissedAdditionalSettingsVCNotification, object: nil)
    }
    
    override func dismissViewController() {
        dismissViewControllerAnimated(true) { () -> Void in
            self.postDismissedNotificationIfNeeded()
        }
    }
    
}

// MARK: - Scroll View Delegate
extension AdditionalSettingsViewController {
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        prepareForDismissingViewController(true)
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        prepareForDismissingViewController(false)
    }
    
    private func makeNavigationBarTransparent(transparent: Bool) {
        UIView.animateWithDuration(0.5) { () -> Void in
            self.navigationController?.navigationBar.alpha = transparent ? 0 : 1
        }
    }
    
    private func prepareForDismissingViewController(prepared: Bool) {
        
        if !prepared {
            UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
                self.customTitleLabel?.alpha = 0
                }, completion: { (_) -> Void in
                    
                    self.customTitleLabel?.text      = self._title
                    self.customTitleLabel?.font      = self._font
                    self.customTitleLabel?.textColor = self._textColor
            })
        }

        UIView.animateWithDuration(0.3, delay: 0.1, options: .CurveEaseInOut, animations: { () -> Void in
            self.customTitleLabel?.alpha = prepared ? 0 : 1
            self.customBarButton?.alpha = prepared ? 0 : 1
            }) { (_) -> Void in
                
                if prepared {
                    self.customTitleLabel?.text      = NSLocalizedString("Pull Down to Close", comment: "")
                    self.customTitleLabel?.textColor = GLOBAL_CUSTOM_COLOR.colorWithAlphaComponent(0.8)
                    self.customTitleLabel?.font      = UIFont.systemFontOfSize(12.0, weight: -1.0)
                }
                
                UIView.animateWithDuration(0.3, delay: 0.1, options: .CurveEaseInOut, animations: { () -> Void in
                    self.customTitleLabel?.alpha = 1
                    }, completion: { (_) -> Void in
                        
                })
        }
    }

    
}

// MARK: - Rotation
extension AdditionalSettingsViewController {
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        // Optimized for 6(s) Plus
        if Device.isEqualToScreenSize(Size.Screen5_5Inch) {
            hideCustomBarButton = toInterfaceOrientation.isLandscape
        }
        
        // FIXME: - After rotating, the position of current popover is not right.
        // Temporarily, I have to dismiss it first on iPad.
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            dismissViewController()
        }
    }
    
}

// MARK: - Table View Delegate
extension AdditionalSettingsViewController {
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        //  @fixed: iPad refusing to accept clear color
        cell.backgroundColor = UIColor.clearColor()
    }
    
    override func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        // change label's text color of Footer View
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        // change label's text color of Header View
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
    }
    
}

// MARK: - Feedback
extension AdditionalSettingsViewController {
    
    @IBAction func feedback(sender: AnyObject) {
        OtherSettingView.defaultSetting.sendMail()
    }
    
}


