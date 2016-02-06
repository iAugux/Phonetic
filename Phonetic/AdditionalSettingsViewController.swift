//
//  AdditionalSettingsViewController.swift
//  Phonetic
//
//  Created by Augus on 2/3/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


let kAdditionalSettingsStatus            = "kAdditionalSettingsStatus"
let kEnableNickname                      = "kEnableNickname"
let kOverwriteNickname                   = "kOverwriteNickname"

let kAdditionalSettingsStatusDefaultBool = true
let kEnableNicknameDefaultBool           = true
let kOverwriteNicknameDefaultBool        = false

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
    
    @IBOutlet weak var statusLabel: UILabel! {
        didSet {
//            statusLabel.text = statusSwitcher.on ? on : off
        }
    }
    
    @IBOutlet weak var statusSwitcher: UISwitch! {
        didSet {
            var isOn: Bool
            if userDefaults.valueForKey(kAdditionalSettingsStatus) == nil {
                isOn = kAdditionalSettingsStatusDefaultBool
            } else {
                isOn = userDefaults.boolForKey(kAdditionalSettingsStatus)
            }
            statusSwitcher.on = isOn
            
//            statusLabel.text = isOn ? on : off
        }
    }

    @IBOutlet weak var nicknameSwitcher: UISwitch! {
        didSet {
            var isOn: Bool
            if userDefaults.valueForKey(kEnableNickname) == nil {
                isOn = kEnableNicknameDefaultBool
            } else {
                isOn = userDefaults.boolForKey(kEnableNickname)
            }
            nicknameSwitcher.on = isOn
        }
    }

    @IBOutlet weak var overwriteNicknameSwitcher: UISwitch! {
        didSet {
            var isOn: Bool
            if userDefaults.valueForKey(kOverwriteNickname) == nil {
                isOn = kOverwriteNicknameDefaultBool
            } else {
                isOn = userDefaults.boolForKey(kOverwriteNickname)
            }
            overwriteNicknameSwitcher.on = isOn
        }
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
        
        statusSwitcher.onTintColor            = GLOBAL_CUSTOM_COLOR
        nicknameSwitcher.onTintColor          = GLOBAL_CUSTOM_COLOR
        overwriteNicknameSwitcher.onTintColor = GLOBAL_CUSTOM_COLOR
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configurePullToDismissViewController(UIColor.clearColor(), fillColor: _color)

        blurBackgroundView = BlurImageView(frame: view.bounds)
        tableView.backgroundView = blurBackgroundView
        tableView.separatorColor = UIColor(red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0)

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

// MARK: - actions of UISwitch
extension AdditionalSettingsViewController {
    
    @IBAction func statusSwitcherDidTap(sender: UISwitch) {
        if sender.on {
            userDefaults.setBool(true, forKey: kAdditionalSettingsStatus)
        } else {
            userDefaults.setBool(false, forKey: kAdditionalSettingsStatus)
        }
        userDefaults.synchronize()
    }
    
    @IBAction func nicknameSwitcherDidTap(sender: UISwitch) {
        if sender.on {
            userDefaults.setBool(true, forKey: kEnableNickname)
        } else {
            userDefaults.setBool(false, forKey: kEnableNickname)
        }
        userDefaults.synchronize()
    }
    
    @IBAction func overwriteNicknameSwitcherDidTap(sender: UISwitch) {
        if sender.on {
            userDefaults.setBool(true, forKey: kOverwriteNickname)
        } else {
            userDefaults.setBool(false, forKey: kOverwriteNickname)
        }
        userDefaults.synchronize()
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
    
}


