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
    
    private let userDefaults = UserDefaults.standard
    
    private let on  = NSLocalizedString("On", comment: "")
    private let off = NSLocalizedString("Off", comment: "")

    private var blurActionSheet: BlurActionSheet!
    
    // MARK: -
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet private weak var tutorialButton: UIButton! {
        didSet {
            tutorialButton.setTitle(NSLocalizedString("Tutorial", comment: ""), for: UIControlState())
        }
    }
    
    @IBOutlet weak var statusSwitch: UISwitch! {
        didSet {
            statusSwitch.shouldSwitch(kAdditionalSettingsStatus, defaultBool: kAdditionalSettingsStatusDefaultBool)
        }
    }
    
    // MARK: - Phonetic Contacts
    @IBOutlet weak var phoneticFirstAndLastNameSwitch: UISwitch! {
        didSet {
            guard DetectPreferredLanguage.isChineseLanguage else {
                phoneticFirstAndLastNameSwitch.isOn = true
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
        if userDefaults.value(forKey: kQuickSearchKeyRawValue) == nil {
            userDefaults.set(QuickSearch.middleName.rawValue, forKey: kQuickSearchKeyRawValue)
            userDefaults.synchronize()
        }
        let rawValue = userDefaults.integer(forKey: kQuickSearchKeyRawValue)
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
    
    
    // MARK: - 
    @IBOutlet weak var separatePinyinSwitch: UISwitch! {
        didSet {
            separatePinyinSwitch.shouldSwitch(kAlwaysSeparatePinyin, defaultBool: kAlwaysSeparatePinyinDefaultBool)
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
    

    // MARK: - Life Cycle

    override func loadView() {
        super.loadView()
        configureQuickSearchSelectionViews()
        
        statusLabel.text                                   = statusSwitch.isOn ? on : off

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
        
        separatePinyinSwitch.onTintColor                   = GLOBAL_CUSTOM_COLOR
        
        forceOpenAnimationSwitch.onTintColor               = SWITCH_TINT_COLOR_FOR_UI_SETTINGS
        keepSettingWindowOpenSwitch.onTintColor            = SWITCH_TINT_COLOR_FOR_UI_SETTINGS


        phoneticFirstAndLastNameSwitch.isEnabled             = DetectPreferredLanguage.isChineseLanguage

        nicknameSwitch.isEnabled                             = statusSwitch.isOn
        customNameSwitch.isEnabled                           = statusSwitch.isOn
        overwriteAlreadyExistsSwitch.isEnabled               = statusSwitch.isOn && (nicknameSwitch.isOn || customNameSwitch.isOn)

        enableAllCleanPhoneticSwitch.isEnabled               = statusSwitch.isOn
        cleanPhoneticNicknameSwitch.isEnabled                = statusSwitch.isOn
        cleanPhoneticMiddleNameSwitch.isEnabled              = statusSwitch.isOn
        cleanPhoneticDepartmentSwitch.isEnabled              = statusSwitch.isOn
        cleanPhoneticCompanySwitch.isEnabled                 = statusSwitch.isOn
        cleanPhoneticJobTitleSwitch.isEnabled                = statusSwitch.isOn
        cleanPhoneticPrefixSwitch.isEnabled                  = statusSwitch.isOn
        cleanPhoneticSuffixSwitch.isEnabled                  = statusSwitch.isOn
        
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
    @IBAction func statusSwitchDidTap(_ sender: UISwitch) {
        
        statusLabel.text = sender.isOn ? on : off
        
        nicknameSwitch.isEnabled                         = sender.isOn
        customNameSwitch.isEnabled                       = sender.isOn
        overwriteAlreadyExistsSwitch.isEnabled           = sender.isOn

        enableAllCleanPhoneticSwitch.isEnabled           = sender.isOn
        cleanPhoneticNicknameSwitch.isEnabled            = sender.isOn
        cleanPhoneticMiddleNameSwitch.isEnabled          = sender.isOn
        cleanPhoneticDepartmentSwitch.isEnabled          = sender.isOn
        cleanPhoneticCompanySwitch.isEnabled             = sender.isOn
        cleanPhoneticJobTitleSwitch.isEnabled            = sender.isOn
        cleanPhoneticPrefixSwitch.isEnabled              = sender.isOn
        cleanPhoneticSuffixSwitch.isEnabled              = sender.isOn
        cleanSocialProfilesKeysSwitch.isEnabled          = sender.isOn
        cleanInstantMessageAddressesKeysSwitch.isEnabled = sender.isOn

        userDefaults.set(sender.isOn, forKey: kAdditionalSettingsStatus)
        userDefaults.synchronize()
    }
    
    // MARK: - Phonetic Contacts
    @IBAction func phoneticFirstAndLastNameSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kPhoneticFirstAndLastName)
        userDefaults.synchronize()
    }

    // MARK: - Quick Search
    @IBAction func nicknameSwitchDidTap(_ sender: UISwitch) {
        
        switchStatusAutomaticallyWithDelay(sender)
        
        if sender.isOn {
            userDefaults.set(true, forKey: kEnableNickname)
            
            overwriteAlreadyExistsSwitch.isEnabled = true
            
//            alertToConfigureForQuickSearchKey()
            
        } else {
            userDefaults.set(false, forKey: kEnableNickname)
            
            // disable `OverwriteAlreadyExistsSwitch` if needed
            if overwriteAlreadyExistsSwitch.isOn && !customNameSwitch.isOn {
                overwriteAlreadyExistsSwitch.isEnabled = false
            }
        }
        userDefaults.synchronize()
    }
    
    @IBAction func customNameSwitchDidTap(_ sender: UISwitch) {
        
        switchStatusAutomaticallyWithDelay(sender)
        
        if sender.isOn {
            userDefaults.set(true, forKey: kEnableCustomName)
            
            overwriteAlreadyExistsSwitch.isEnabled = true
            
        } else {
            userDefaults.set(false, forKey: kEnableCustomName)
            
            // disable `OverwriteAlreadyExistsSwitch` if needed
            if overwriteAlreadyExistsSwitch.isOn && !nicknameSwitch.isOn {
                overwriteAlreadyExistsSwitch.isEnabled = false
            }
        }
        userDefaults.synchronize()
    }
    
    @IBAction func overwriteAlreadyExistsSwitchDidTap(_ sender: UISwitch) {
        if sender.isOn {
            userDefaults.set(true, forKey: kOverwriteAlreadyExists)
            
            switchStatusAutomaticallyWithDelay(sender)
            
        } else {
            userDefaults.set(false, forKey: kOverwriteAlreadyExists)
        }
        userDefaults.synchronize()
    }
    
    
    // MARK: - Clean Phonetic Keys
    @IBAction func enableAllCleanPhoneticSwitchDidTap(_ sender: UISwitch) {
        enableAllCleanPhoneticSwitchWithAlert(sender.isOn)
    }
    
    @IBAction func cleanPhoneticNicknameKeysSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kCleanPhoneticNickname)
        userDefaults.synchronize()
    }
    
    @IBAction func cleanPhoneticMiddleNameKeysSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kCleanPhoneticMiddleName)
        userDefaults.synchronize()
    }
    
    @IBAction func cleanPhoneticDepartmentKeysSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kCleanPhoneticDepartment)
        userDefaults.synchronize()
    }
    
    @IBAction func cleanPhoneticCompanyKeysSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kCleanPhoneticCompany)
        userDefaults.synchronize()
    }
    
    @IBAction func cleanPhoneticjobTitleKeysSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kCleanPhoneticJobTitle)
        userDefaults.synchronize()
    }
    
    @IBAction func cleanPhoneticPrefixKeysSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kCleanPhoneticPrefix)
        userDefaults.synchronize()
    }
    
    @IBAction func cleanPhoneticSuffixKeysSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kCleanPhoneticSuffix)
        userDefaults.synchronize()
    }
    
    @IBAction func cleanSocialProfilesKeysSwitchDidTap(_ sender: UISwitch) {
        enableCleanSocialProfilesSwitchWithAlert(sender.isOn)
    }
    
    @IBAction func cleanInstantMessageAddressesKeysSwitchDidTap(_ sender: UISwitch) {
        enableCleanInstantMessageAddressesSwitchWithAlert(sender.isOn)
    }
    
    
    // MARK: - 
    @IBAction func separatePinyinSwitchDidTap(_ sender: AnyObject) {
        userDefaults.set(sender.isOn, forKey: kAlwaysSeparatePinyin)
        userDefaults.synchronize()
    }
    
    
    // MARK: - UI
    @IBAction func forceOpenAnimationSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kForceEnableAnimation)
        userDefaults.synchronize()
    }
    
    @IBAction func keepSettingWindowOpenSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kKeepSettingsWindowOpen)
        userDefaults.synchronize()
    }
    
    // MARK: - Turn On/Off Switch Automatically
    private func switchStatusAutomaticallyWithDelay(_ sender: UISwitch) {
        
        executeAfterDelay(0.2) { 
            if sender == self.overwriteAlreadyExistsSwitch && !self.customNameSwitch.isOn {
                if let _ = self.nicknameSwitch?.setOn(true, animated: true) {
                    self.userDefaults.set(true, forKey: kEnableNickname)
                }
                return
            }
            
            if sender.isOn {
                switch sender {
                case self.nicknameSwitch:
                    if let _ = self.customNameSwitch?.setOn(false, animated: true) {
                        self.userDefaults.set(false, forKey: kEnableCustomName)
                    }
                    
                case self.customNameSwitch:
                    if let _ = self.nicknameSwitch?.setOn(false, animated: true) {
                        self.userDefaults.set(false, forKey: kEnableNickname)
                    }
                default: break
                }
            }

        }
    }
    
    private func enableAllCleanPhoneticSwitchWithDelay(_ enabled: Bool, delay: Bool) {
        
        let delayInSeconds: Double = delay ? 0.2 : 0.0
        
        executeAfterDelay(delayInSeconds) {
            self.userDefaults.set(enabled, forKey: kCleanPhoneticNickname)
            self.userDefaults.set(enabled, forKey: kCleanPhoneticMiddleName)
            self.userDefaults.set(enabled, forKey: kCleanPhoneticDepartment)
            self.userDefaults.set(enabled, forKey: kCleanPhoneticCompany)
            self.userDefaults.set(enabled, forKey: kCleanPhoneticJobTitle)
            self.userDefaults.set(enabled, forKey: kCleanPhoneticPrefix)
            self.userDefaults.set(enabled, forKey: kCleanPhoneticSuffix)
            
            if self.userDefaults.synchronize() {
                self.cleanPhoneticNicknameSwitch.setOn(enabled, animated: true)
                self.cleanPhoneticMiddleNameSwitch.setOn(enabled, animated: true)
                self.cleanPhoneticDepartmentSwitch.setOn(enabled, animated: true)
                self.cleanPhoneticCompanySwitch.setOn(enabled, animated: true)
                self.cleanPhoneticJobTitleSwitch.setOn(enabled, animated: true)
                self.cleanPhoneticPrefixSwitch.setOn(enabled, animated: true)
                self.cleanPhoneticSuffixSwitch.setOn(enabled, animated: true)
            }
            
            // switch off SocialProfilesKeysSwitch & InstantMessageAddressesKeysSwitch too.
            if !enabled {
                self.userDefaults.set(false, forKey: kCleanSocialProfilesKeys)
                self.userDefaults.set(false, forKey: kCleanInstantMessageAddressesKeys)
                
                if self.userDefaults.synchronize() {
                    self.cleanSocialProfilesKeysSwitch.setOn(false, animated: true)
                    self.cleanInstantMessageAddressesKeysSwitch.setOn(false, animated: true)
                }
            }
        }
    }
}

// MARK: - Switch With Alert
extension AdditionalSettingsViewController {
    
    private func enableAllCleanPhoneticSwitchWithAlert(_ enabled: Bool) {
        
        let title = NSLocalizedString("Clean All Keys", comment: "UIAlertController title")
        let message = NSLocalizedString("Are you sure to clean all keys? All of those keys including you manually added before will be removed too!", comment: "UIAlertController message")
        
        enableAllCleanPhoneticSwitch.switchWithAlert(title, message: message, okActionTitle: NSLocalizedString("Clean", comment: ""), on: enabled) { () -> Void in
            self.userDefaults.set(enabled, forKey: kEnableAllCleanPhonetic)
            if self.userDefaults.synchronize() {
                self.enableAllCleanPhoneticSwitchWithDelay(enabled, delay: !enabled)
            }
        }
    }
    
    private func enableCleanSocialProfilesSwitchWithAlert(_ enabled: Bool) {
        let title = NSLocalizedString("Clean Keys", comment: "UIAlertController title")
        let message = NSLocalizedString("Are you sure to clean Social Profiles keys? This can not be revoked!!", comment: "UIAlertController message")
        
        let social = String(format: "\n\n Tencent Weibo\n\n Game Center\n\n Sina Weibo\n\n Facebook\n\n MySpace\n\n LinkedIn\n\n Twitter\n\n Flickr\n\n Yelp")
        
        cleanSocialProfilesKeysSwitch.switchWithAlert(title, message: message + social, okActionTitle: NSLocalizedString("Clean", comment: ""), on: enabled) { () -> Void in
            self.userDefaults.set(enabled, forKey: kCleanSocialProfilesKeys)
            if self.userDefaults.synchronize() {
                self.cleanSocialProfilesKeysSwitch.setOn(enabled, animated: true)
            }
        }
    }
    
    private func enableCleanInstantMessageAddressesSwitchWithAlert(_ enabled: Bool) {
        let title = NSLocalizedString("Clean Keys", comment: "UIAlertController title")
        let message = NSLocalizedString("Are you sure to clean Instant Message Addresses keys? This can not be revoked!!", comment: "UIAlertController message")
        
        let im = String(format: "\n\n Facebook Messenger\n\n Yahoo! Messenger\n\n MSN Messenger\n\n Google Talk\n\n Gadu-Gadu\n\n Jabber\n\n Skype\n\n AIM\n\n ICQ\n\n QQ")
        
        cleanInstantMessageAddressesKeysSwitch.switchWithAlert(title, message: message + im, okActionTitle: NSLocalizedString("Clean", comment: ""), on: enabled) { () -> Void in
            self.userDefaults.set(enabled, forKey: kCleanInstantMessageAddressesKeys)
            if self.userDefaults.synchronize() {
                self.cleanInstantMessageAddressesKeysSwitch.setOn(enabled, animated: true)
            }
        }
    }
   
}

extension UISwitch {
    
    fileprivate func switchWithAlert(_ title: String, message: String, okActionTitle: String, on: Bool, closure: @escaping (() -> Void)) {
        if on {
            AlertController.alertWithCancelAction(title, message: message, actionTitle: okActionTitle, completionHandler: { () -> Void in
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
        quickSearchSelectionIndicator.tintColor = UIColor.white
        quickSearchSelectionIndicator.image = UIImage(named: "expand")?.withRenderingMode(.alwaysTemplate)
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(alertActionSheetToChooseCustomKeyForQuickSearch))
        quickSearchSelectionLabel.addGestureRecognizer(recognizer)
        quickSearchSelectionLabel.isUserInteractionEnabled = true
        quickSearchSelectionLabel.text = String.localizedStringWithFormat(NSLocalizedString("%@ for Quick Search", comment: ""), quickSearchKey)
    }
    
}

// MARK: - Action Sheet for choosing custom key for Quick Search
extension AdditionalSettingsViewController {
    
    @objc internal func alertActionSheetToChooseCustomKeyForQuickSearch() {
        
        quickSearchSelectionIndicator.rotationAnimation(beginWithClockwise: false, clockwise: false, animated: true)
        
        var actionSheetTitles = [String]()
        
        for i in 0...QuickSearch.cancel.rawValue {
            actionSheetTitles.append(QuickSearch(rawValue: i)!.key)
        }
        
        executeAfterDelay(0.2) {
            
            self.blurActionSheet = BlurActionSheet.showWithTitles(actionSheetTitles) { (index) -> Void in
                
                executeAfterDelay(0.1, closure: {
                    self.quickSearchSelectionIndicator.rotationAnimation(beginWithClockwise: false, clockwise: true, animated: true)
                })
                
                // action canceled
                guard (actionSheetTitles.count - 1) != index else { return }
                
                UserDefaults.standard.set(index, forKey: kQuickSearchKeyRawValue)
                if UserDefaults.standard.synchronize() {
                    self.quickSearchSelectionLabel.text = String.localizedStringWithFormat(NSLocalizedString("%@ for Quick Search", comment: ""), actionSheetTitles[index])
                }
                self.tableView.reloadData()
            }
        }
    }
    
}


// MARK: -
extension AdditionalSettingsViewController: TableViewHeaderFooterViewWithButtonDelegate {
    
    func tableViewHeaderFooterViewWithButtonDidTap() {
        let vc = UIStoryboard.Main.instantiateViewController(with: HelpManualViewController.self)
        navigationController?.pushViewController(vc, animated: true)
    }
}


// MARK: - Table View Datasource
extension AdditionalSettingsViewController {
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        switch section {
        case 2:
            let headerView = TableViewHeaderFooterViewWithButton(buttonImageName: "help")
            headerView.delegate = self
            return headerView
            
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var headerTitle: String?
        
        switch section {
        case 0:
            headerTitle = NSLocalizedString("Phonetic Contacts", comment: "Table view header title")
            
        case 2:
            headerTitle = NSLocalizedString("Quick Search", comment: "Table view header title")
            
        case 3:
            headerTitle = NSLocalizedString("Clean Phonetic Keys", comment: "Table view header title")
  
        case 5:
            headerTitle = NSLocalizedString("User Interface Settings", comment: "Table view header title")
            
        default: break
        }
        
        return headerTitle
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        var footerTitle: String?
        
        switch section {
        case 0:
            footerTitle = NSLocalizedString("Sort contacts under the English system. If the device language is not Chinese, the switch will be forced open.", comment: "Table view footer title")
            
        case 2:
            footerTitle = String.localizedStringWithFormat(NSLocalizedString("e.g: Add a phonetic Nickname / %@ key for `叶梓萱` with `YZX`. Then you can enter `YZX` to search the specific name.", comment: "Table view footer title"), quickSearchKey)
            
        case 3:
            footerTitle = NSLocalizedString("⚠️ Be Careful. All of those keys including you manually added before will be removed!「Select keys you want to delete and go back to Main Interface, Long Press to clean」", comment: "Table view footer title")
            
        case 4:
            footerTitle = "e.g: 叶梓萱 [ Ye Zi Xuan ]"
            
        case 5:
            footerTitle = NSLocalizedString("Enable animation even audio is playing in background.", comment: "Table view footer title")
            
        case 6:
            footerTitle = NSLocalizedString("Keep `Settings Window` open after dismissing `Additional Settings Window`.", comment: "Table view footer title")
            
        default: break
        }
        
        return footerTitle
    }
    
}

extension AdditionalSettingsViewController {
    
    private func alertToConfigureForQuickSearchKey() {
        UIApplication.initializeInTheFirstTime("alertToConfigureForQuickSearchKeyOnlyOnce") { () -> Void in
            let title = NSLocalizedString("Setting", comment: "UIAlertController title")
            let message = NSLocalizedString("Please tap the yellow button to complete settings. This message is only displayed once!", comment: "UIAlertController message")
            AlertController.alert(title, message: message, completionHandler: nil)
        }
    }
}


// MARK: - Rotation
extension AdditionalSettingsViewController {
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        
        if UIDevice.current.isPad {
            dismissViewController(completion: {
                kShouldRepresentAdditionalVC = true
            })
        }
    }
}


// MARK: -

extension AdditionalSettingsViewController {
    
    @IBAction func tutorialButtonDidTap(_ sender: AnyObject) {
        
        if !UIDevice.current.isPad {
            dismiss(animated: true) {
                displayWalkthrough()
            }
            
        } else {
            dismiss(animated: true, completion: {
                appDelegate.getVisibleViewController()?.dismiss(animated: true, completion: {
                    displayWalkthrough()
                })
            })
        }
    }
    
}
