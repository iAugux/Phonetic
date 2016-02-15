//
//  AdditionalSettingsViewController.swift
//  Phonetic
//
//  Created by Augus on 2/3/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


let kDismissedAdditionalSettingsVCNotification = "kDismissedAdditionalSettingsVCNotification"

let SWITCH_TINT_COLOR_FOR_UI_SETTINGS = UIColor(red: 0.4395, green: 0.8138, blue: 0.9971, alpha: 1.0)

class AdditionalSettingsViewController: UITableViewController {
    
    @IBOutlet weak var quickSearchSelectionIndicator: UIImageView!
    @IBOutlet weak var quickSearchSelectionLabel: UILabel!
    
    private let userDefaults = NSUserDefaults.standardUserDefaults()
    
    private let on           = NSLocalizedString("On", comment: "")
    private let off          = NSLocalizedString("Off", comment: "")
    private let _title       = NSLocalizedString("Additional Settings", comment: "UINavigationController title - Additional Settings")
    
    private let _color       = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
    private let _font        = UIFont.systemFontOfSize(17.0)
    private let _textColor   = UIColor.whiteColor()
    
    private var blurBackgroundView: BlurImageView!
    private var customBarButton: UIButton!
    private var customTitleLabel: UILabel!
    private var customStatusBar: UIView!
    
    private var blurActionSheet: BlurActionSheet!
    
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
            customBarButton?.hidden = hideCustomBarButton
        }
    }
    
    // MARK: - Deinit
    deinit {
        tableView.dg_removePullToRefresh()
    }
    
    // MARK: -
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var statusSwitch: UISwitch! {
        didSet {
            statusSwitch.shouldSwitch(kAdditionalSettingsStatus, defaultBool: kAdditionalSettingsStatusDefaultBool)
        }
    }
    
    // MARK: - Quick Search
    @IBOutlet weak var nicknameSwitch: UISwitch! {
        didSet {
            nicknameSwitch.shouldSwitch(kEnableNickname, defaultBool: kEnableNicknameDefaultBool)
        }
    }
    
    @IBOutlet weak var customNameSwitch: UISwitch! {
        didSet {
            customNameSwitch.shouldSwitch(kEnableCustomName, defaultBool: kEnableCustomNameDefaultBool)
        }
    }
    
    @IBOutlet weak var overwriteAlreadyExistsSwitch: UISwitch! {
        didSet {
            overwriteAlreadyExistsSwitch.shouldSwitch(kOverwriteAlreadyExists, defaultBool: kOverwriteAlreadyExistsDefaultBool)
        }
    }
    
    private var quickSearchKey: String {
        if userDefaults.valueForKey(kQuickSearchKey) == nil {
            userDefaults.setValue(QuickSearch.MiddleName.key, forKey: kQuickSearchKey)
            userDefaults.synchronize()
        }
        return userDefaults.stringForKey(kQuickSearchKey)!
    }
    
    
    // MARK: - Clean Phonetic Keys
    
    @IBOutlet weak var enableAllCleanPhoneticSwitch: UISwitch! {
        didSet {
            enableAllCleanPhoneticSwitch.shouldSwitch(kEnableAllCleanPhonetic, defaultBool: kEnableAllCleanPhoneticDefaultBool)
        }
    }
    
    @IBOutlet weak var cleanPhoneticNicknameSwitch: UISwitch! {
        didSet {
            cleanPhoneticNicknameSwitch.shouldSwitch(kCleanPhoneticNickname, defaultBool: kCleanPhoneticNicknameDefaultBool)
        }
    }
    
    @IBOutlet weak var cleanPhoneticMiddleNameSwitch: UISwitch! {
        didSet {
            cleanPhoneticMiddleNameSwitch.shouldSwitch(kCleanPhoneticMiddleName, defaultBool: kCleanPhoneticMiddleNameDefaultBool)
        }
    }
    
    @IBOutlet weak var cleanPhoneticDepartmentSwitch: UISwitch! {
        didSet {
            cleanPhoneticDepartmentSwitch.shouldSwitch(kCleanPhoneticDepartment, defaultBool: kCleanPhoneticDepartmentDefaultBool)
        }
    }
    
    @IBOutlet weak var cleanPhoneticCompanySwitch: UISwitch! {
        didSet {
            cleanPhoneticCompanySwitch.shouldSwitch(kCleanPhoneticCompany, defaultBool: kCleanPhoneticCompanyDefaultBool)
        }
    }
    
    @IBOutlet weak var cleanPhoneticJobTitleSwitch: UISwitch! {
        didSet {
            cleanPhoneticJobTitleSwitch.shouldSwitch(kCleanPhoneticJobTitle, defaultBool: kCleanPhoneticJobTitleDefaultBool)
        }
    }
    
    @IBOutlet weak var cleanPhoneticPrefixSwitch: UISwitch! {
        didSet {
            cleanPhoneticPrefixSwitch.shouldSwitch(kCleanPhoneticPrefix, defaultBool: kCleanPhoneticPrefixDefaultBool)
        }
    }
    
    @IBOutlet weak var cleanPhoneticSuffixSwitch: UISwitch! {
        didSet {
            cleanPhoneticSuffixSwitch.shouldSwitch(kCleanPhoneticSuffix, defaultBool: kCleanPhoneticSuffixDefaultBool)
        }
    }
    
    // MARK: - UI
    @IBOutlet weak var forceOpenAnimationSwitch: UISwitch! {
        didSet {
            forceOpenAnimationSwitch.shouldSwitch(kForceEnableAnimation, defaultBool: kForceEnableAnimationDefaultBool)
        }
    }
    
    @IBOutlet weak var keepSettingWindowOpenSwitch: UISwitch! {
        didSet {
            keepSettingWindowOpenSwitch.shouldSwitch(kKeepSettingsWindowOpen, defaultBool: kKeepSettingsWindowOpenDefaultBool)
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
        navigationController?.navigationBar.tintColor = GLOBAL_CUSTOM_COLOR.darkerColor(0.9)
        
        configureCustomStatusBar()
        configureCustomBarButtonIfNeeded()
        configureCustomTitleLabel()
        configureQuickSearchSelectionViews()
        
        statusLabel.text                          = statusSwitch.on ? on : off
        statusSwitch.onTintColor                  = GLOBAL_CUSTOM_COLOR
        nicknameSwitch.onTintColor                = GLOBAL_CUSTOM_COLOR
        customNameSwitch.onTintColor              = GLOBAL_CUSTOM_COLOR
        overwriteAlreadyExistsSwitch.onTintColor  = GLOBAL_CUSTOM_COLOR
        
        enableAllCleanPhoneticSwitch.onTintColor  = GLOBAL_CUSTOM_COLOR
        cleanPhoneticNicknameSwitch.onTintColor   = GLOBAL_CUSTOM_COLOR
        cleanPhoneticMiddleNameSwitch.onTintColor = GLOBAL_CUSTOM_COLOR
        cleanPhoneticDepartmentSwitch.onTintColor = GLOBAL_CUSTOM_COLOR
        cleanPhoneticCompanySwitch.onTintColor    = GLOBAL_CUSTOM_COLOR
        cleanPhoneticJobTitleSwitch.onTintColor   = GLOBAL_CUSTOM_COLOR
        cleanPhoneticPrefixSwitch.onTintColor     = GLOBAL_CUSTOM_COLOR
        cleanPhoneticSuffixSwitch.onTintColor     = GLOBAL_CUSTOM_COLOR
        
        forceOpenAnimationSwitch.onTintColor      = SWITCH_TINT_COLOR_FOR_UI_SETTINGS
        keepSettingWindowOpenSwitch.onTintColor   = SWITCH_TINT_COLOR_FOR_UI_SETTINGS
        
        nicknameSwitch.enabled                    = statusSwitch.on
        customNameSwitch.enabled                  = statusSwitch.on
        overwriteAlreadyExistsSwitch.enabled      = statusSwitch.on && (nicknameSwitch.on || customNameSwitch.on)
        
        enableAllCleanPhoneticSwitch.enabled      = statusSwitch.on
        cleanPhoneticNicknameSwitch.enabled       = statusSwitch.on
        cleanPhoneticMiddleNameSwitch.enabled     = statusSwitch.on
        cleanPhoneticDepartmentSwitch.enabled     = statusSwitch.on
        cleanPhoneticCompanySwitch.enabled        = statusSwitch.on
        cleanPhoneticJobTitleSwitch.enabled       = statusSwitch.on
        cleanPhoneticPrefixSwitch.enabled         = statusSwitch.on
        cleanPhoneticSuffixSwitch.enabled         = statusSwitch.on
        
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
        fixCustomViewsFrameIfNeeded()
        fixCustomStatusBarFrameIfNeeded()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureCustomBarButtonIfNeeded()
        customBarButton?.alpha = 0
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
            self.customBarButton?.alpha = 1
            }) { (_) -> Void in
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
            self.customBarButton?.alpha = 0
            }) { (_) -> Void in
                self.customBarButton?.removeFromSuperview()
                self.customBarButton = nil
        }
    }
    
}

// MARK: - Actions of UISwitch
extension AdditionalSettingsViewController {
    
    // MARK: - Master Switch
    @IBAction func statusSwitchDidTap(sender: UISwitch) {
        
        statusLabel.text = sender.on ? on : off
        
        nicknameSwitch.enabled                = sender.on
        customNameSwitch.enabled              = sender.on
        overwriteAlreadyExistsSwitch.enabled  = sender.on
        
        enableAllCleanPhoneticSwitch.enabled  = sender.on
        cleanPhoneticNicknameSwitch.enabled   = sender.on
        cleanPhoneticMiddleNameSwitch.enabled = sender.on
        cleanPhoneticDepartmentSwitch.enabled = sender.on
        cleanPhoneticCompanySwitch.enabled    = sender.on
        cleanPhoneticJobTitleSwitch.enabled   = sender.on
        cleanPhoneticPrefixSwitch.enabled     = sender.on
        cleanPhoneticSuffixSwitch.enabled     = sender.on

        userDefaults.setBool(sender.on, forKey: kAdditionalSettingsStatus)
        userDefaults.synchronize()
    }
    
    
    // MARK: - Quick Search
    @IBAction func nicknameSwitchDidTap(sender: UISwitch) {
        
        switchStatusAutomaticallyWithDelay(sender)
        
        if sender.on {
            userDefaults.setBool(true, forKey: kEnableNickname)
            
            overwriteAlreadyExistsSwitch.enabled = true
            
        } else {
            userDefaults.setBool(false, forKey: kEnableNickname)
            
            // disable `OverwriteAlreadyExistsSwitch` if needed
            if overwriteAlreadyExistsSwitch.on && !customNameSwitch.on {
                overwriteAlreadyExistsSwitch.enabled = false
            }
        }
        userDefaults.synchronize()
    }
    
    @IBAction func customNameSwitchDidTap(sender: UISwitch) {
        
        switchStatusAutomaticallyWithDelay(sender)
        
        if sender.on {
            userDefaults.setBool(true, forKey: kEnableCustomName)
            
            overwriteAlreadyExistsSwitch.enabled = true
            
        } else {
            userDefaults.setBool(false, forKey: kEnableCustomName)
            
            // disable `OverwriteAlreadyExistsSwitch` if needed
            if overwriteAlreadyExistsSwitch.on && !nicknameSwitch.on {
                overwriteAlreadyExistsSwitch.enabled = false
            }
        }
        userDefaults.synchronize()
    }
    
    @IBAction func overwriteAlreadyExistsSwitchDidTap(sender: UISwitch) {
        if sender.on {
            userDefaults.setBool(true, forKey: kOverwriteAlreadyExists)
            
            switchStatusAutomaticallyWithDelay(sender)
            
        } else {
            userDefaults.setBool(false, forKey: kOverwriteAlreadyExists)
        }
        userDefaults.synchronize()
    }
    
    
    // MARK: - Clean Phonetic Keys
    @IBAction func enableAllCleanPhoneticSwitchDidTap(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: kEnableAllCleanPhonetic)
        
        if userDefaults.synchronize() {
            enableAllCleanPhoneticSwitchWithDelay(sender.on)
        }
    }
    
    @IBAction func cleanPhoneticNicknameKeysSwitchDidTap(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: kCleanPhoneticNickname)
        userDefaults.synchronize()
    }
    
    @IBAction func cleanPhoneticMiddleNameKeysSwitchDidTap(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: kCleanPhoneticMiddleName)
        userDefaults.synchronize()
    }
    
    @IBAction func cleanPhoneticDepartmentKeysSwitchDidTap(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: kCleanPhoneticDepartment)
        userDefaults.synchronize()
    }
    
    @IBAction func cleanPhoneticCompanyKeysSwitchDidTap(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: kCleanPhoneticCompany)
        userDefaults.synchronize()
    }
    
    @IBAction func cleanPhoneticjobTitleKeysSwitchDidTap(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: kCleanPhoneticJobTitle)
        userDefaults.synchronize()
    }
    
    @IBAction func cleanPhoneticPrefixKeysSwitchDidTap(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: kCleanPhoneticPrefix)
        userDefaults.synchronize()
    }
    
    @IBAction func cleanPhoneticSuffixKeysSwitchDidTap(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: kCleanPhoneticSuffix)
        userDefaults.synchronize()
    }
    
    // MARK: - UI
    @IBAction func forceOpenAnimationSwitchDidTap(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: kForceEnableAnimation)
        userDefaults.synchronize()
    }
    
    @IBAction func keepSettingWindowOpenSwitchDidTap(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: kKeepSettingsWindowOpen)
        userDefaults.synchronize()
    }
    
    // MARK: - Turn On/Off Switch Automatically
    private func switchStatusAutomaticallyWithDelay(sender: UISwitch) {
        
        let delayInSeconds: Double = 0.2
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * delayInSeconds))
        dispatch_after(popTime, dispatch_get_main_queue(), {
            
            if sender == self.overwriteAlreadyExistsSwitch && !self.customNameSwitch.on {
                if let _ = self.nicknameSwitch?.setOn(true, animated: true) {
                    self.userDefaults.setBool(true, forKey: kEnableNickname)
                }
                return
            }
            
            if sender.on {
                switch sender {
                case self.nicknameSwitch:
                    if let _ = self.customNameSwitch?.setOn(false, animated: true) {
                        self.userDefaults.setBool(false, forKey: kEnableCustomName)
                    }
                    
                case self.customNameSwitch:
                    if let _ = self.nicknameSwitch?.setOn(false, animated: true) {
                        self.userDefaults.setBool(false, forKey: kEnableNickname)
                    }
                default: break
                }
            }
        })
        
    }
    
    private func enableAllCleanPhoneticSwitchWithDelay(enabled: Bool) {
        let delayInSeconds: Double = 0.2
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * delayInSeconds))
        dispatch_after(popTime, dispatch_get_main_queue(), {
            
            self.userDefaults.setBool(enabled, forKey: kCleanPhoneticNickname)
            self.userDefaults.setBool(enabled, forKey: kCleanPhoneticMiddleName)
            self.userDefaults.setBool(enabled, forKey: kCleanPhoneticDepartment)
            self.userDefaults.setBool(enabled, forKey: kCleanPhoneticCompany)
            self.userDefaults.setBool(enabled, forKey: kCleanPhoneticJobTitle)
            self.userDefaults.setBool(enabled, forKey: kCleanPhoneticPrefix)
            self.userDefaults.setBool(enabled, forKey: kCleanPhoneticSuffix)
            
            if self.userDefaults.synchronize() {
                self.cleanPhoneticNicknameSwitch.setOn(enabled, animated: true)
                self.cleanPhoneticMiddleNameSwitch.setOn(enabled, animated: true)
                self.cleanPhoneticDepartmentSwitch.setOn(enabled, animated: true)
                self.cleanPhoneticCompanySwitch.setOn(enabled, animated: true)
                self.cleanPhoneticJobTitleSwitch.setOn(enabled, animated: true)
                self.cleanPhoneticPrefixSwitch.setOn(enabled, animated: true)
                self.cleanPhoneticSuffixSwitch.setOn(enabled, animated: true)
            }
        })
    }
    
}

// MARK: - Configure Subviews
extension AdditionalSettingsViewController {
    
    private func configureQuickSearchSelectionViews() {
        quickSearchSelectionIndicator.tintColor = UIColor.whiteColor()
        quickSearchSelectionIndicator.image = UIImage(named: "expand")?.imageWithRenderingMode(.AlwaysTemplate)
        
        let recognizer = UITapGestureRecognizer(target: self, action: "alertActionSheetToChooseCustomKeyForQuickSearch")
        quickSearchSelectionLabel.addGestureRecognizer(recognizer)
        quickSearchSelectionLabel.userInteractionEnabled = true
        quickSearchSelectionLabel.text = NSLocalizedString("\(quickSearchKey) for Quick Search", comment: "")
    }
    
    private func configureCustomStatusBar() {
        
        guard UIDevice.currentDevice().userInterfaceIdiom != .Pad else { return }
        
        customStatusBar = UIView(frame: UIApplication.sharedApplication().statusBarFrame)
        customStatusBar.backgroundColor = _color
        
        UIApplication.topMostViewController()?.view.addSubview(customStatusBar)
    }
    
    private func configureCustomBarButtonIfNeeded() {
        guard customBarButton == nil else { return }
        
        customBarButton = UIButton(type: .Custom)
        customBarButton.setImage(UIImage(named: "close")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        customBarButton.tintColor   = UIColor.whiteColor()
        customBarButton.frame.size  = CGSizeMake(25, 25)
        customBarButton.contentMode = .Center
        customBarButton.addTarget(self, action: "dismissViewController", forControlEvents: .TouchUpInside)
        
        navigationController?.navigationBar.addSubview(customBarButton)
        
        hideCustomBarButton = shouldHideCustomBarButton
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
    
    private func fixCustomStatusBarFrameIfNeeded() {
        guard UIDevice.currentDevice().userInterfaceIdiom != .Pad else { return }
        
        if UIScreen.screenWidth() < UIScreen.screenHeight() {
            customStatusBar?.frame = UIApplication.sharedApplication().statusBarFrame
        } else {
            customStatusBar?.frame = CGRectZero
        }
    }
    
    private func fixCustomViewsFrameIfNeeded() {
        if let navigationBar = navigationController?.navigationBar {
            customBarButton?.center = navigationBar.center
            customBarButton?.frame.origin.x = 8.0
            customTitleLabel?.center = navigationBar.center
            
            if UIScreen.screenWidth() < UIScreen.screenHeight() && UIDevice.currentDevice().userInterfaceIdiom != .Pad {
                customBarButton?.frame.origin.y -= UIApplication.sharedApplication().statusBarFrame.height
                customTitleLabel?.frame.origin.y -= UIApplication.sharedApplication().statusBarFrame.height
            }
        }
    }
    
    private func setRotationAnimation(view: UIView, beginWithClockwise: Bool, clockwise: Bool, animated: Bool) {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        
        let angle: Double = beginWithClockwise ? (clockwise ? M_PI : 0) : (clockwise ? 0 : -M_PI)
        
        if beginWithClockwise {
            if !clockwise { rotationAnimation.fromValue = M_PI }
        } else {
            if clockwise { rotationAnimation.fromValue = -M_PI }
        }
        
        
        rotationAnimation.toValue = angle
        rotationAnimation.duration = animated ? 0.4 : 0
        rotationAnimation.repeatCount = 0
        rotationAnimation.delegate = self
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        rotationAnimation.fillMode = kCAFillModeForwards
        rotationAnimation.removedOnCompletion = false
        
        view.layer.addAnimation(rotationAnimation, forKey: "rotationAnimation")
    }
    
}

// MARK: - Action Sheet for choosing custom key for Quick Search
extension AdditionalSettingsViewController {
    
    internal func alertActionSheetToChooseCustomKeyForQuickSearch() {
        setRotationAnimation(quickSearchSelectionIndicator, beginWithClockwise: false, clockwise: false, animated: true)
        
        let actionSheetTitles = [QuickSearch.MiddleName.key,
            QuickSearch.Department.key,
            QuickSearch.Company.key,
            QuickSearch.JobTitle.key,
            QuickSearch.Prefix.key,
            QuickSearch.Suffix.key,
            QuickSearch.Cancel.key
        ]
        
        blurActionSheet = BlurActionSheet.showWithTitles(actionSheetTitles) { (index) -> Void in
            self.setRotationAnimation(self.quickSearchSelectionIndicator, beginWithClockwise: false, clockwise: true, animated: true)
            
            // action canceled
            guard (actionSheetTitles.count - 1) != index else { return }
            
            NSUserDefaults.standardUserDefaults().setValue(actionSheetTitles[index], forKey: kQuickSearchKey)
            if NSUserDefaults.standardUserDefaults().synchronize() {
                self.quickSearchSelectionLabel.text = NSLocalizedString("\(actionSheetTitles[index]) for Quick Search", comment: "")
            }
            self.tableView.reloadData()
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
        // TODO: - Direction
//        if scrollView.panGestureRecognizer.translationInView(scrollView.superview).y > 0 {
//        }
        prepareForDismissingViewController(true)
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        if scrollView.panGestureRecognizer.translationInView(scrollView.superview).y > 0 {
//        }
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
                    self.customTitleLabel?.text      = NSLocalizedString("Pull Down to Dismiss", comment: "")
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
            
            // FIXME: -
            blurActionSheet?.removeFromSuperview()
        }
    }
    
    
}

extension AdditionalSettingsViewController: TableViewHeaderFooterViewWithButtonDelegate {
    
    func tableViewHeaderFooterViewWithButtonDidTap() {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("HelpManualViewController") as? UIViewController {
            print("bbb")
            // HelpManualNavigationController
            
//            UIApplication.topMostViewController()?.presentViewController(vc, animated: true, completion: nil)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}

// MARK: - Table View Datasource
extension AdditionalSettingsViewController {
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        switch section {
        case 2:            
            let headerView = TableViewHeaderFooterViewWithButton(buttonImageName: "help")
            headerView.delegate = self
            return headerView
            
        default: return nil
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var headerTitle: String?
        
        switch section {
        case 1:
            headerTitle = NSLocalizedString("Quick Search", comment: "Table view header title")
            
        case 2:
            headerTitle = NSLocalizedString("Clean Phonetic Keys", comment: "Table view header title")
            
        case 3:
            headerTitle = NSLocalizedString("User Interface Setting", comment: "Table view header title")
            
        default: break
        }
        
        return headerTitle
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        var footerTitle: String?
        
        switch section {
        case 1:
            footerTitle = NSLocalizedString("e.g: Add a phonetic Nickname / \(quickSearchKey) key for `叶梓萱` with `YZX`. Then you can enter `YZX` to search the specific name. ", comment: "Table view footer title")
            
        case 2:
            footerTitle = ""
            
        case 3:
            footerTitle = NSLocalizedString("Enable animation even audio is playing in background.", comment: "Table view footer title")
            
        case 4:
            footerTitle = NSLocalizedString("Keep `Settings Window` open after dismissing `Additional Settings Window`.", comment: "Table view footer title")
            
        default: break
        }
        
        return footerTitle
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


