//
//  AdditionalSettingsViewController.swift
//  Phonetic
//
//  Created by Augus on 2/3/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit
import Device
import Components

final class AdditionalSettingsViewController: BaseTableViewController {
    private let userDefaults = UserDefaults.standard
    private let on = NSLocalizedString("On", comment: "")
    private let off = NSLocalizedString("Off", comment: "")
    private var blurActionSheet: BlurActionSheet!

    @IBOutlet private var quickSearchSelectionIndicator: UIImageView!
    @IBOutlet private var quickSearchSelectionLabel: UILabel!
    @IBOutlet private var statusLabel: UILabel!
    @IBOutlet private var whitelistLabel: UILabel! { didSet { whitelistLabel.text = NSLocalizedString("Whitelists", comment: "") } }
    @IBOutlet private var chooseLanguageLabel: UILabel! { didSet { chooseLanguageLabel.text = NSLocalizedString("Choose Language", comment: "") } }
    @IBOutlet private var chooseLanguageCell: CustomTableViewCell! { didSet { chooseLanguageCell.isHidden = !hasPassedReviewOfApple } }
    @IBOutlet private var tutorialButton: UIButton! { didSet { tutorialButton.setTitle(NSLocalizedString("Tutorial", comment: ""), for: .normal) } }
    @IBOutlet private var statusSwitch: UISwitch! { didSet { statusSwitch.shouldSwitch(for: kAdditionalSettingsStatus, default: kAdditionalSettingsStatusDefaultBool) } }
    @IBOutlet private var nicknameSwitch: UISwitch! { didSet { nicknameSwitch.shouldSwitch(for: kEnableNickname, default: kEnableNicknameDefaultBool) } }
    @IBOutlet private var customNameSwitch: UISwitch! { didSet { customNameSwitch.shouldSwitch(for: kEnableCustomName, default: kEnableCustomNameDefaultBool) } }
    @IBOutlet private var overwriteAlreadyExistsSwitch: UISwitch! { didSet { overwriteAlreadyExistsSwitch.shouldSwitch(for: kOverwriteAlreadyExists, default: kOverwriteAlreadyExistsDefaultBool) } }
    @IBOutlet private var enableAllCleanPhoneticSwitch: UISwitch! { didSet { enableAllCleanPhoneticSwitch.shouldSwitch(for: kEnableAllCleanPhonetic, default: kEnableAllCleanPhoneticDefaultBool) } }

    @IBOutlet private var cleanPhoneticNicknameSwitch: UISwitch! { didSet { cleanPhoneticNicknameSwitch.shouldSwitch(for: kCleanPhoneticNickname, default: kCleanPhoneticNicknameDefaultBool) } }

    @IBOutlet private var cleanMiddleNameKeySwitch: UISwitch! { didSet { cleanMiddleNameKeySwitch.shouldSwitch(for: kCleanPhoneticMiddleName, default: kCleanPhoneticMiddleNameDefaultBool) } }
    @IBOutlet private var cleanNotesKeySwitch: UISwitch! { didSet { cleanNotesKeySwitch.shouldSwitch(for: kCleanNotesKey, default: kCleanNotesKeyDefaultBool) } }
    @IBOutlet private var cleanPhoneticDepartmentSwitch: UISwitch! { didSet { cleanPhoneticDepartmentSwitch.shouldSwitch(for: kCleanPhoneticDepartment, default: kCleanPhoneticDepartmentDefaultBool) } }
    @IBOutlet private var cleanPhoneticCompanySwitch: UISwitch! { didSet { cleanPhoneticCompanySwitch.shouldSwitch(for: kCleanPhoneticCompany, default: kCleanPhoneticCompanyDefaultBool) } }
    @IBOutlet private var cleanPhoneticJobTitleSwitch: UISwitch! { didSet { cleanPhoneticJobTitleSwitch.shouldSwitch(for: kCleanPhoneticJobTitle, default: kCleanPhoneticJobTitleDefaultBool) } }
    @IBOutlet private var cleanPhoneticPrefixSwitch: UISwitch! { didSet { cleanPhoneticPrefixSwitch.shouldSwitch(for: kCleanPhoneticPrefix, default: kCleanPhoneticPrefixDefaultBool) } }
    @IBOutlet private var cleanPhoneticSuffixSwitch: UISwitch! { didSet { cleanPhoneticSuffixSwitch.shouldSwitch(for: kCleanPhoneticSuffix, default: kCleanPhoneticSuffixDefaultBool) } }
    @IBOutlet private var cleanSocialProfilesKeysSwitch: UISwitch! { didSet { cleanSocialProfilesKeysSwitch.shouldSwitch(for: kCleanSocialProfilesKeys, default: kCleanSocialProfilesKeysDefaultBool) } }
    @IBOutlet private var cleanInstantMessageAddressesKeysSwitch: UISwitch! { didSet { cleanInstantMessageAddressesKeysSwitch.shouldSwitch(for: kCleanInstantMessageAddressesKeys, default: kCleanInstantMessageKeysDefaultBool) } }
    @IBOutlet private var separatePinyinSwitch: UISwitch! { didSet { separatePinyinSwitch.shouldSwitch(for: kAlwaysSeparatePinyin, default: kAlwaysSeparatePinyinDefaultBool) } }
    @IBOutlet private var massageCompanyKeySwitch: UISwitch! { didSet { massageCompanyKeySwitch.shouldSwitch(for: kMassageCompanyKey, default: kMassageCompanyKeyDefaultBool) } }

    @IBOutlet private var phoneticFirstAndLastNameSwitch: UISwitch! {
        didSet {
            guard DetectPreferredLanguage.isChineseLanguage else {
                phoneticFirstAndLastNameSwitch.isOn = true
                return
            }
            phoneticFirstAndLastNameSwitch.shouldSwitch(for: kPhoneticFirstAndLastName, default: kPhoneticFirstAndLastNameDefaultBool)
        }
    }

    private var quickSearchKey: String {
        if userDefaults.value(forKey: kQuickSearchKeyRawValue) == nil {
            userDefaults.set(QuickSearch.notes.rawValue, forKey: kQuickSearchKeyRawValue)
        }
        let rawValue = userDefaults.integer(forKey: kQuickSearchKeyRawValue)
        return QuickSearch(rawValue: rawValue)?.key ?? QuickSearch(rawValue: 0)!.key
    }

    // MARK: - Life Cycle
    override func loadView() {
        super.loadView()
        configureScreenEdgeDismissGesture()
        configureQuickSearchSelectionViews()

        statusLabel.text = statusSwitch.isOn ? on : off
        phoneticFirstAndLastNameSwitch.isEnabled = DetectPreferredLanguage.isChineseLanguage
        overwriteAlreadyExistsSwitch.isEnabled = statusSwitch.isOn && (nicknameSwitch.isOn || customNameSwitch.isOn)

        [nicknameSwitch,
         customNameSwitch,
         enableAllCleanPhoneticSwitch,
         cleanPhoneticNicknameSwitch,
         cleanMiddleNameKeySwitch,
         cleanNotesKeySwitch,
         cleanPhoneticDepartmentSwitch,
         cleanPhoneticCompanySwitch,
         cleanPhoneticJobTitleSwitch,
         cleanPhoneticPrefixSwitch,
         cleanPhoneticSuffixSwitch,
        ].forEach { $0.isEnabled = statusSwitch.isOn }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Additional Settings", comment: "SettingsNavigationController title - Additional Settings")
        let image = #imageLiteral(resourceName: "close").withRenderingMode(.alwaysTemplate)
        navigationItem.leftBarButtonItem = BarButtonItem(image: image, target: self, action: .dismissAnimated)
    }
}

// MARK: - Actions of UISwitch
extension AdditionalSettingsViewController {
    // MARK: - Master Switch
    @IBAction func statusSwitchDidTap(_ sender: UISwitch) {
        statusLabel.text = sender.isOn ? on : off

        [nicknameSwitch,
         customNameSwitch,
         overwriteAlreadyExistsSwitch,
         enableAllCleanPhoneticSwitch,
         cleanPhoneticNicknameSwitch,
         cleanMiddleNameKeySwitch,
         cleanNotesKeySwitch,
         cleanPhoneticDepartmentSwitch,
         cleanPhoneticCompanySwitch,
         cleanPhoneticJobTitleSwitch,
         cleanPhoneticPrefixSwitch,
         cleanPhoneticSuffixSwitch,
         cleanSocialProfilesKeysSwitch,
         cleanInstantMessageAddressesKeysSwitch,
        ].forEach { $0.isEnabled = sender.isOn }

        userDefaults.set(sender.isOn, forKey: kAdditionalSettingsStatus)
    }

    // MARK: - Phonetic Contacts
    @IBAction func phoneticFirstAndLastNameSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kPhoneticFirstAndLastName)
    }
    
    // MARK: - Quick Search
    @IBAction func nicknameSwitchDidTap(_ sender: UISwitch) {
        switchStatusAutomaticallyWithDelay(sender)
        if sender.isOn {
            userDefaults.set(true, forKey: kEnableNickname)
            overwriteAlreadyExistsSwitch.isEnabled = true
        } else {
            userDefaults.set(false, forKey: kEnableNickname)
            // disable `OverwriteAlreadyExistsSwitch` if needed
            if overwriteAlreadyExistsSwitch.isOn && !customNameSwitch.isOn { overwriteAlreadyExistsSwitch.isEnabled = false }
        }
    }
    
    @IBAction func customNameSwitchDidTap(_ sender: UISwitch) {
        switchStatusAutomaticallyWithDelay(sender)
        if sender.isOn {
            userDefaults.set(true, forKey: kEnableCustomName)
            overwriteAlreadyExistsSwitch.isEnabled = true
        } else {
            userDefaults.set(false, forKey: kEnableCustomName)
            // disable `OverwriteAlreadyExistsSwitch` if needed
            if overwriteAlreadyExistsSwitch.isOn && !nicknameSwitch.isOn { overwriteAlreadyExistsSwitch.isEnabled = false }
        }
    }
    
    @IBAction func overwriteAlreadyExistsSwitchDidTap(_ sender: UISwitch) {
        if sender.isOn {
            userDefaults.set(true, forKey: kOverwriteAlreadyExists)
            switchStatusAutomaticallyWithDelay(sender)
        } else {
            userDefaults.set(false, forKey: kOverwriteAlreadyExists)
        }
    }
    
    // MARK: - Clean Contacts Keys
    @IBAction func enableAllCleanPhoneticSwitchDidTap(_ sender: UISwitch) {
        enableAllCleanPhoneticSwitchWithAlert(sender.isOn)
    }
    
    @IBAction func cleanPhoneticNicknameKeysSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kCleanPhoneticNickname)
    }
    
    @IBAction func cleanPhoneticMiddleNameKeysSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kCleanPhoneticMiddleName)
    }
    
    @IBAction func cleanNotesKeySwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kCleanNotesKey)
    }
    
    @IBAction func cleanPhoneticDepartmentKeysSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kCleanPhoneticDepartment)
    }
    
    @IBAction func cleanPhoneticCompanyKeysSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kCleanPhoneticCompany)
    }
    
    @IBAction func cleanPhoneticjobTitleKeysSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kCleanPhoneticJobTitle)
    }
    
    @IBAction func cleanPhoneticPrefixKeysSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kCleanPhoneticPrefix)
    }
    
    @IBAction func cleanPhoneticSuffixKeysSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kCleanPhoneticSuffix)
    }
    
    @IBAction func cleanSocialProfilesKeysSwitchDidTap(_ sender: UISwitch) {
        enableCleanSocialProfilesSwitchWithAlert(sender.isOn)
    }
    
    @IBAction func cleanInstantMessageAddressesKeysSwitchDidTap(_ sender: UISwitch) {
        enableCleanInstantMessageAddressesSwitchWithAlert(sender.isOn)
    }
    
    @IBAction func separatePinyinSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kAlwaysSeparatePinyin)
    }
    
    @IBAction func massageCompanyKeySwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kMassageCompanyKey)
        enableMassageCompanyKeySwitchWithAlert(sender.isOn)
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

            guard sender.isOn else { return }
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
    
    private func enableAllCleanPhoneticSwitchWithDelay(_ enabled: Bool, delay: Bool) {
        let delayInSeconds: Double = delay ? 0.2 : 0.0
        executeAfterDelay(delayInSeconds) { [weak self] in
            guard let self = self else { return }
            self.userDefaults.set(enabled, forKey: kCleanPhoneticNickname)
            self.userDefaults.set(enabled, forKey: kCleanPhoneticMiddleName)
            self.userDefaults.set(enabled, forKey: kCleanNotesKey)
            self.userDefaults.set(enabled, forKey: kCleanPhoneticDepartment)
            self.userDefaults.set(enabled, forKey: kCleanPhoneticCompany)
            self.userDefaults.set(enabled, forKey: kCleanPhoneticJobTitle)
            self.userDefaults.set(enabled, forKey: kCleanPhoneticPrefix)
            self.userDefaults.set(enabled, forKey: kCleanPhoneticSuffix)
            self.cleanPhoneticNicknameSwitch.setOn(enabled, animated: true)
            self.cleanMiddleNameKeySwitch.setOn(enabled, animated: true)
            self.cleanNotesKeySwitch.setOn(enabled, animated: true)
            self.cleanPhoneticDepartmentSwitch.setOn(enabled, animated: true)
            self.cleanPhoneticCompanySwitch.setOn(enabled, animated: true)
            self.cleanPhoneticJobTitleSwitch.setOn(enabled, animated: true)
            self.cleanPhoneticPrefixSwitch.setOn(enabled, animated: true)
            self.cleanPhoneticSuffixSwitch.setOn(enabled, animated: true)
            // switch off SocialProfilesKeysSwitch & InstantMessageAddressesKeysSwitch too.
            guard !enabled else { return }
            self.userDefaults.set(false, forKey: kCleanSocialProfilesKeys)
            self.userDefaults.set(false, forKey: kCleanInstantMessageAddressesKeys)
            self.cleanSocialProfilesKeysSwitch.setOn(false, animated: true)
            self.cleanInstantMessageAddressesKeysSwitch.setOn(false, animated: true)
        }
    }
}

// MARK: - Switch With Alert
extension AdditionalSettingsViewController {
    private func enableAllCleanPhoneticSwitchWithAlert(_ enabled: Bool) {
        let title = NSLocalizedString("Clean All Keys", comment: "UIAlertController title")
        let message = NSLocalizedString("Are you sure to clean all keys? All of those keys including you manually added before will be removed too!", comment: "UIAlertController message")
        enableAllCleanPhoneticSwitch.switchWithAlert(title, message: message, okActionTitle: NSLocalizedString("Clean", comment: ""), on: enabled) {
            self.userDefaults.set(enabled, forKey: kEnableAllCleanPhonetic)
            self.enableAllCleanPhoneticSwitchWithDelay(enabled, delay: !enabled)
        }
    }
    
    private func enableCleanSocialProfilesSwitchWithAlert(_ enabled: Bool) {
        let title = NSLocalizedString("Clean Keys", comment: "UIAlertController title")
        let message = NSLocalizedString("Are you sure to clean Social Profiles keys? This can not be revoked!!", comment: "UIAlertController message")
        let social = String(format: "\n\n Tencent Weibo\n\n Game Center\n\n Sina Weibo\n\n Facebook\n\n MySpace\n\n LinkedIn\n\n Twitter\n\n Flickr\n\n Yelp")
        cleanSocialProfilesKeysSwitch.switchWithAlert(title, message: message + social, okActionTitle: NSLocalizedString("Clean", comment: ""), on: enabled) {
            self.userDefaults.set(enabled, forKey: kCleanSocialProfilesKeys)
            self.cleanSocialProfilesKeysSwitch.setOn(enabled, animated: true)
        }
    }
    
    private func enableCleanInstantMessageAddressesSwitchWithAlert(_ enabled: Bool) {
        let title = NSLocalizedString("Clean Keys", comment: "UIAlertController title")
        let message = NSLocalizedString("Are you sure to clean Instant Message Addresses keys? This can not be revoked!!", comment: "UIAlertController message")
        let im = String(format: "\n\n Facebook Messenger\n\n Yahoo! Messenger\n\n MSN Messenger\n\n Google Talk\n\n Gadu-Gadu\n\n Jabber\n\n Skype\n\n AIM\n\n ICQ\n\n QQ")
        cleanInstantMessageAddressesKeysSwitch.switchWithAlert(title, message: message + im, okActionTitle: NSLocalizedString("Clean", comment: ""), on: enabled) {
            self.userDefaults.set(enabled, forKey: kCleanInstantMessageAddressesKeys)
            self.cleanInstantMessageAddressesKeysSwitch.setOn(enabled, animated: true)
        }
    }
    
    private func enableMassageCompanyKeySwitchWithAlert(_ enabled: Bool) {
        guard enabled else { return }
        let title = NSLocalizedString("Please Note", comment: "")
        let message = NSLocalizedString("The company key will be automatically copied as a given name, then generating the Phonetic Given Name for sorting and the Quick Search key for searching.", comment: "UIAlertController message")
        AlertController.alert(title, message: message, completionHandler: nil)
    }
}

extension UISwitch {
    fileprivate func switchWithAlert(_ title: String, message: String, okActionTitle: String, on: Bool, closure: @escaping Closure) {
        guard on else { closure(); return }
        AlertController.alertWithCancelAction(title, message: message, actionTitle: okActionTitle, completionHandler: { closure() }, canceledHandler: { [unowned self] in
            self.setOn(false, animated: true)
        })
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
    @objc private func alertActionSheetToChooseCustomKeyForQuickSearch() {
        quickSearchSelectionIndicator.rotate(by: -180°, duration: 0.4)
        var actionSheetTitles = [String]()
        for i in 0...QuickSearch.cancel.rawValue {
            actionSheetTitles.append(QuickSearch(rawValue: i)!.key)
        }
        executeAfterDelay(0.2) { [weak self] in
            guard let self = self else { return }
            self.blurActionSheet = BlurActionSheet.showWithTitles(actionSheetTitles) { index -> Void in
                executeAfterDelay(0.1, closure: { self.quickSearchSelectionIndicator.reverseTransform(duration: 0.4) })
                // action canceled
                guard (actionSheetTitles.count - 1) != index else { return }
                UserDefaults.standard.set(index, forKey: kQuickSearchKeyRawValue)
                self.quickSearchSelectionLabel.text = String.localizedStringWithFormat(NSLocalizedString("%@ for Quick Search", comment: ""), actionSheetTitles[index])
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: - Table view data source
extension AdditionalSettingsViewController {
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 3:
            let headerView = TableViewHeaderFooterViewWithButton(buttonImageName: "help")
            headerView.tapHandler = { [unowned self] in
                let vc = UIStoryboard.Main.instantiateViewController(with: HelpManualViewController.self)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            return headerView
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var headerTitle: String?
        switch section {
        case 3:
            headerTitle = NSLocalizedString("Quick Search", comment: "Table view header title")
        case 4:
            headerTitle = NSLocalizedString("Clean Contacts Keys", comment: "Table view header title")
        default: break
        }
        return headerTitle
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        var footerTitle: String?
        switch section {
        case 1:
            footerTitle = NSLocalizedString("Sort contacts under the English system. If the device language is not Chinese, the switch will be forced open.", comment: "Table view footer title")
        case 3:
            footerTitle = String.localizedStringWithFormat(NSLocalizedString("e.g: Add a phonetic Nickname / %@ key for `叶梓萱` with `YZX`. Then you can enter `YZX` to search the specific name.", comment: "Table view footer title"), quickSearchKey)
        case 4:
            footerTitle = NSLocalizedString("Be Careful. All of those keys including you manually added before will be removed!「Select keys you want to delete and go back to Main Interface, Long Press to clean」", comment: "Table view footer title")
        case 5:
            footerTitle = NSLocalizedString("Only for contact which has company key but no name.", comment: "Table view footer title")
        case 6:
            footerTitle = "e.g: 叶梓萱 [ Ye Zi Xuan ]"
        default: break
        }
        return footerTitle
    }
}

// MARK: - Table View Delegate
extension AdditionalSettingsViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == IndexPath(row: 0, section: 0) { // Whitelists
            presentAlert(message: "Please check on App Store...", actionTitle: "OK") { _ in
                UIApplication.shared.openURL(APP.appStoreURL(with: "1078961574"))
            }
            return
        }

        // select language
        guard indexPath.section == 7 else { return }
        var actionSheetTitles = [String]()
        for i in 0 ... CustomLanguage.cancel.rawValue {
            actionSheetTitles.append(CustomLanguage(rawValue: i)!.description)
        }
        blurActionSheet = BlurActionSheet.showWithTitles(actionSheetTitles) { [unowned self] index -> Void in
            self.tableView.reloadData()
            // action canceled
            guard (actionSheetTitles.count - 1) != index else { return }
            let languages = CustomLanguage(rawValue: index)?.langs
            UserDefaults.standard.set(languages, forKey: kAppleLanguages)
            executeAfterDelay(0.3, closure: {
                UIApplication.shared.perform(#selector(URLSessionTask.suspend))
                executeAfterDelay(1.0, closure: {
                    exit(0)
                })
            })
        }
    }
}

extension AdditionalSettingsViewController {
    private func alertToConfigureForQuickSearchKey() {
        UIApplication.shared.initializeInTheFirstTime(key: "alertToConfigureForQuickSearchKeyOnlyOnce") {
            let title = NSLocalizedString("Setting", comment: "UIAlertController title")
            let message = NSLocalizedString("Please tap the yellow button to complete settings. This message is only displayed once!", comment: "UIAlertController message")
            AlertController.alert(title, message: message, completionHandler: nil)
        }
    }
}

// MARK: -
extension AdditionalSettingsViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard UIDevice.current.isPad else { return }
        if segue.identifier == "PresentDonationViewController" {
            dismissAnimated()
            return
        }
        // fix WhitelistViewController's position on iPad after rotation
        guard segue.identifier == "PresentWhitelistViewControllerIdentifier" else { return }
        let vc = segue.destination
        guard let view = AppDelegate.shared.window?.rootViewController?.view else { return }
        vc.popoverPresentationController?.sourceView = view
        vc.popoverPresentationController?.sourceRect = CGRect(origin: view.center, size: CGSize.zero)
        vc.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        // deselect whitelist cell programmably
        let whitelistCellIndexPath = IndexPath(row: 0, section: 0)
        tableView.deselectRow(at: whitelistCellIndexPath, animated: true)
    }
}

// MARK: - Rotation
extension AdditionalSettingsViewController {
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        guard UIDevice.current.isPad else { return }
        guard let view = AppDelegate.shared.window?.rootViewController?.view else { return }
        navigationController?.popoverPresentationController?.sourceRect = CGRect(origin: view.center, size: CGSize.zero)
    }
}

// MARK: -
extension AdditionalSettingsViewController {
    @IBAction func tutorialButtonDidTap(_ sender: AnyObject) {
        guard UIDevice.current.isPad else {
            dismiss(animated: true) { displayWalkthrough() }
            return
        }
        dismiss(animated: true, completion: {
            AppDelegate.shared.visibleViewController()?.dismiss(animated: true, completion: {
                displayWalkthrough()
            })
        })
    }
}
