//
//  AdditionalSettingsViewController.swift
//  Phonetic
//
//  Created by Augus on 2/3/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


let SWITCH_TINT_COLOR_FOR_UI_SETTINGS = UIColor(red: 0.4395, green: 0.8138, blue: 0.9971, alpha: 1.0)

class AdditionalSettingsViewController: BaseTableViewController {
    
    @IBOutlet weak var quickSearchSelectionIndicator: UIImageView!
    @IBOutlet weak var quickSearchSelectionLabel: UILabel!
    
    private let userDefaults = NSUserDefaults.standardUserDefaults()
    
    private let on  = NSLocalizedString("On", comment: "")
    private let off = NSLocalizedString("Off", comment: "")

    private var blurActionSheet: BlurActionSheet!
    
    // MARK: -
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var statusSwitch: UISwitch! {
        didSet {
            statusSwitch.shouldSwitch(kAdditionalSettingsStatus, defaultBool: kAdditionalSettingsStatusDefaultBool)
        }
    }
    
    // MARK: - Phonetic Contacts
    @IBOutlet weak var phoneticFirstAndLastNameSwitch: UISwitch! {
        didSet {
            guard DetectPreferredLanguage.isChineseLanguage else {
                phoneticFirstAndLastNameSwitch.on = true
                return
            }
            
            phoneticFirstAndLastNameSwitch.shouldSwitch(kPhoneticFirstAndLastName, defaultBool: kPhoneticFirstAndLastNameDefaultBool)
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
        if userDefaults.valueForKey(kQuickSearchKeyRawValue) == nil {
            userDefaults.setInteger(QuickSearch.MiddleName.rawValue, forKey: kQuickSearchKeyRawValue)
            userDefaults.synchronize()
        }
        let rawValue = userDefaults.integerForKey(kQuickSearchKeyRawValue)
        return QuickSearch(rawValue: rawValue)?.key ?? QuickSearch(rawValue: 0)!.key
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
    
    @IBOutlet weak var cleanSocialProfilesKeysSwitch: UISwitch! {
        didSet {
            cleanSocialProfilesKeysSwitch.shouldSwitch(kCleanSocialProfilesKeys, defaultBool: kCleanSocialProfilesKeysDefaultBool)
        }
    }
    
    @IBOutlet weak var cleanInstantMessageAddressesKeysSwitch: UISwitch! {
        didSet {
            cleanInstantMessageAddressesKeysSwitch.shouldSwitch(kCleanInstantMessageAddressesKeys, defaultBool: kCleanInstantMessageKeysDefaultBool)
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
    
}

// MARK: - Life Cycle
extension AdditionalSettingsViewController {
    
    override func loadView() {
        super.loadView()
        configureQuickSearchSelectionViews()
        
        statusLabel.text                                   = statusSwitch.on ? on : off

        phoneticFirstAndLastNameSwitch.onTintColor         = GLOBAL_CUSTOM_COLOR

        statusSwitch.onTintColor                           = GLOBAL_CUSTOM_COLOR
        nicknameSwitch.onTintColor                         = GLOBAL_CUSTOM_COLOR
        customNameSwitch.onTintColor                       = GLOBAL_CUSTOM_COLOR
        overwriteAlreadyExistsSwitch.onTintColor           = GLOBAL_CUSTOM_COLOR

        enableAllCleanPhoneticSwitch.onTintColor           = GLOBAL_CUSTOM_COLOR
        cleanPhoneticNicknameSwitch.onTintColor            = GLOBAL_CUSTOM_COLOR
        cleanPhoneticMiddleNameSwitch.onTintColor          = GLOBAL_CUSTOM_COLOR
        cleanPhoneticDepartmentSwitch.onTintColor          = GLOBAL_CUSTOM_COLOR
        cleanPhoneticCompanySwitch.onTintColor             = GLOBAL_CUSTOM_COLOR
        cleanPhoneticJobTitleSwitch.onTintColor            = GLOBAL_CUSTOM_COLOR
        cleanPhoneticPrefixSwitch.onTintColor              = GLOBAL_CUSTOM_COLOR
        cleanPhoneticSuffixSwitch.onTintColor              = GLOBAL_CUSTOM_COLOR
        cleanSocialProfilesKeysSwitch.onTintColor          = GLOBAL_CUSTOM_COLOR
        cleanInstantMessageAddressesKeysSwitch.onTintColor = GLOBAL_CUSTOM_COLOR

        forceOpenAnimationSwitch.onTintColor               = SWITCH_TINT_COLOR_FOR_UI_SETTINGS
        keepSettingWindowOpenSwitch.onTintColor            = SWITCH_TINT_COLOR_FOR_UI_SETTINGS


        phoneticFirstAndLastNameSwitch.enabled             = DetectPreferredLanguage.isChineseLanguage

        nicknameSwitch.enabled                             = statusSwitch.on
        customNameSwitch.enabled                           = statusSwitch.on
        overwriteAlreadyExistsSwitch.enabled               = statusSwitch.on && (nicknameSwitch.on || customNameSwitch.on)

        enableAllCleanPhoneticSwitch.enabled               = statusSwitch.on
        cleanPhoneticNicknameSwitch.enabled                = statusSwitch.on
        cleanPhoneticMiddleNameSwitch.enabled              = statusSwitch.on
        cleanPhoneticDepartmentSwitch.enabled              = statusSwitch.on
        cleanPhoneticCompanySwitch.enabled                 = statusSwitch.on
        cleanPhoneticJobTitleSwitch.enabled                = statusSwitch.on
        cleanPhoneticPrefixSwitch.enabled                  = statusSwitch.on
        cleanPhoneticSuffixSwitch.enabled                  = statusSwitch.on
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _title = NSLocalizedString("Additional Settings", comment: "SettingsNavigationController title - Additional Settings")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

// MARK: - Actions of UISwitch
extension AdditionalSettingsViewController {
    
    // MARK: - Master Switch
    @IBAction func statusSwitchDidTap(sender: UISwitch) {
        
        statusLabel.text = sender.on ? on : off
        
        nicknameSwitch.enabled                         = sender.on
        customNameSwitch.enabled                       = sender.on
        overwriteAlreadyExistsSwitch.enabled           = sender.on

        enableAllCleanPhoneticSwitch.enabled           = sender.on
        cleanPhoneticNicknameSwitch.enabled            = sender.on
        cleanPhoneticMiddleNameSwitch.enabled          = sender.on
        cleanPhoneticDepartmentSwitch.enabled          = sender.on
        cleanPhoneticCompanySwitch.enabled             = sender.on
        cleanPhoneticJobTitleSwitch.enabled            = sender.on
        cleanPhoneticPrefixSwitch.enabled              = sender.on
        cleanPhoneticSuffixSwitch.enabled              = sender.on
        cleanSocialProfilesKeysSwitch.enabled          = sender.on
        cleanInstantMessageAddressesKeysSwitch.enabled = sender.on

        userDefaults.setBool(sender.on, forKey: kAdditionalSettingsStatus)
        userDefaults.synchronize()
    }
    
    // MARK: - Phonetic Contacts
    @IBAction func phoneticFirstAndLastNameSwitchDidTap(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: kPhoneticFirstAndLastName)
        userDefaults.synchronize()
    }

    // MARK: - Quick Search
    @IBAction func nicknameSwitchDidTap(sender: UISwitch) {
        
        switchStatusAutomaticallyWithDelay(sender)
        
        if sender.on {
            userDefaults.setBool(true, forKey: kEnableNickname)
            
            overwriteAlreadyExistsSwitch.enabled = true
            
            alertToConfigureForQuickSearchKey()
            
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
        enableAllCleanPhoneticSwitchWithAlert(sender.on)
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
    
    @IBAction func cleanSocialProfilesKeysSwitchDidTap(sender: UISwitch) {
        enableCleanSocialProfilesSwitchWithAlert(sender.on)
    }
    
    @IBAction func cleanInstantMessageAddressesKeysSwitchDidTap(sender: UISwitch) {
        enableCleanInstantMessageAddressesSwitchWithAlert(sender.on)
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
    
    private func enableAllCleanPhoneticSwitchWithDelay(enabled: Bool, delay: Bool) {
        
        let delayInSeconds: Double = delay ? 0.2 : 0.0
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

// MARK: - Switch With Alert
extension AdditionalSettingsViewController {
    
    private func enableAllCleanPhoneticSwitchWithAlert(enabled: Bool) {
        
        let title = NSLocalizedString("Clean All Keys", comment: "UIAlertViewController title")
        let message = NSLocalizedString("Are you sure to clean all keys? All of those keys including you manually added before will be removed too! This can not be revoked!!", comment: "UIAlertViewController message")
        
        enableAllCleanPhoneticSwitch.switchWithAlert(title, message: message, okActionTitle: NSLocalizedString("Clean", comment: ""), on: enabled) { () -> Void in
            self.userDefaults.setBool(enabled, forKey: kEnableAllCleanPhonetic)
            if self.userDefaults.synchronize() {
                self.enableAllCleanPhoneticSwitchWithDelay(enabled, delay: !enabled)
            }
        }
    }
    
    private func enableCleanSocialProfilesSwitchWithAlert(enabled: Bool) {
        let title = NSLocalizedString("Clean Keys", comment: "UIAlertViewController title")
        let message = NSLocalizedString("Are you sure to clean Social Profiles keys? This can not be revoked!!", comment: "UIAlertViewController message")
        
        let social = String(format: "\n\n Tencent Weibo\n\n Game Center\n\n Sina Weibo\n\n Facebook\n\n MySpace\n\n LinkedIn\n\n Twitter\n\n Flickr\n\n Yelp")
        
        cleanSocialProfilesKeysSwitch.switchWithAlert(title, message: message + social, okActionTitle: NSLocalizedString("Clean", comment: ""), on: enabled) { () -> Void in
            self.userDefaults.setBool(enabled, forKey: kCleanSocialProfilesKeys)
            if self.userDefaults.synchronize() {
                self.cleanSocialProfilesKeysSwitch.setOn(enabled, animated: true)
            }
        }
    }
    
    private func enableCleanInstantMessageAddressesSwitchWithAlert(enabled: Bool) {
        let title = NSLocalizedString("Clean Keys", comment: "UIAlertViewController title")
        let message = NSLocalizedString("Are you sure to clean Instant Message Addresses keys? This can not be revoked!!", comment: "UIAlertViewController message")
        
        let im = String(format: "\n\n Facebook Messenger\n\n Yahoo! Messenger\n\n MSN Messenger\n\n Google Talk\n\n Gadu-Gadu\n\n Jabber\n\n Skype\n\n AIM\n\n ICQ\n\n QQ")
        
        cleanInstantMessageAddressesKeysSwitch.switchWithAlert(title, message: message + im, okActionTitle: NSLocalizedString("Clean", comment: ""), on: enabled) { () -> Void in
            self.userDefaults.setBool(enabled, forKey: kCleanInstantMessageAddressesKeys)
            if self.userDefaults.synchronize() {
                self.cleanInstantMessageAddressesKeysSwitch.setOn(enabled, animated: true)
            }
        }
    }
   
}

extension UISwitch {
    
    private func switchWithAlert(title: String, message: String, okActionTitle: String, on: Bool, closure: (() -> Void)) {
        if on {
            AlertController.alertWithCancelAction(title: title, message: message, actionTitle: okActionTitle, completionHandler: { () -> Void in
                closure()
                }, canceledHandler: { () -> Void in
                    self.setOn(false, animated: true)
            })
        } else {
            closure()
        }
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
        quickSearchSelectionLabel.text = String.localizedStringWithFormat(NSLocalizedString("%@ for Quick Search", comment: ""), quickSearchKey)
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
        
        var actionSheetTitles = [String]()
        
        for i in 0...QuickSearch.Cancel.rawValue {
            actionSheetTitles.append(QuickSearch(rawValue: i)!.key)
        }
        
        blurActionSheet = BlurActionSheet.showWithTitles(actionSheetTitles) { (index) -> Void in
            self.setRotationAnimation(self.quickSearchSelectionIndicator, beginWithClockwise: false, clockwise: true, animated: true)
            
            // action canceled
            guard (actionSheetTitles.count - 1) != index else { return }
            
            NSUserDefaults.standardUserDefaults().setInteger(index, forKey: kQuickSearchKeyRawValue)
            if NSUserDefaults.standardUserDefaults().synchronize() {
                self.quickSearchSelectionLabel.text = String.localizedStringWithFormat(NSLocalizedString("%@ for Quick Search", comment: ""), actionSheetTitles[index])
            }
            self.tableView.reloadData()
        }
    }
    
}

// MARK: - Rotation
extension AdditionalSettingsViewController {
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willRotateToInterfaceOrientation(toInterfaceOrientation, duration: duration)
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            // FIXME: -
            blurActionSheet?.removeFromSuperview()
        }
    }
}

extension AdditionalSettingsViewController: TableViewHeaderFooterViewWithButtonDelegate {
    
    func tableViewHeaderFooterViewWithButtonDidTap() {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier(String(HelpManualViewController)) as? HelpManualViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}

// MARK: - Table View Datasource
extension AdditionalSettingsViewController {
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        switch section {
        case 2:
            let headerView = TableViewHeaderFooterViewWithButton(buttonImageName: "help", tintColor: UIColor(red:1.0, green:1.0, blue:0.4, alpha:1.0))
            headerView.delegate = self
            return headerView
            
        default: return nil
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var headerTitle: String?
        
        switch section {
        case 0:
            headerTitle = NSLocalizedString("Phonetic Contacts", comment: "Table view header title")
            
        case 2:
            headerTitle = NSLocalizedString("Quick Search", comment: "Table view header title")
            
        case 3:
            headerTitle = NSLocalizedString("Clean Phonetic Keys", comment: "Table view header title")
            
        case 4:
            headerTitle = NSLocalizedString("User Interface Settings", comment: "Table view header title")
            
        default: break
        }
        
        return headerTitle
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        var footerTitle: String?
        
        switch section {
        case 0:
            footerTitle = NSLocalizedString("If the device language is not Chinese, the switch will be forced open.", comment: "Table view footer title")
            
        case 2:
            footerTitle = String.localizedStringWithFormat(NSLocalizedString("e.g: Add a phonetic Nickname / %@ key for `叶梓萱` with `YZX`. Then you can enter `YZX` to search the specific name.", comment: "Table view footer title"), quickSearchKey)
            
        case 3:
            footerTitle = NSLocalizedString("⚠️ Be Careful. All of those keys including you manually added before will be removed!", comment: "Table view footer title")
            
        case 4:
            footerTitle = NSLocalizedString("Enable animation even audio is playing in background.", comment: "Table view footer title")
            
        case 5:
            footerTitle = NSLocalizedString("Keep `Settings Window` open after dismissing `Additional Settings Window`.", comment: "Table view footer title")
            
        default: break
        }
        
        return footerTitle
    }
    
}

extension AdditionalSettingsViewController {
    
    private func alertToConfigureForQuickSearchKey() {
        UIApplication.initializeInTheFirstTime("alertToConfigureForQuickSearchKeyOnlyOnce") { () -> Void in
            let title = NSLocalizedString("Setting", comment: "UIAlertViewController title")
            let message = NSLocalizedString("Please tap the yellow button to complete settings. This message is only displayed once!", comment: "UIAlertViewController message")
            AlertController.alert(title: title, message: message, completionHandler: nil)
        }
    }
}


