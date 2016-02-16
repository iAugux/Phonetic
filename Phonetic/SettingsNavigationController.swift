//
//  SettingsNavigationController.swift
//  Phonetic
//
//  Created by Augus on 2/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

class SettingsNavigationController: UINavigationController {

    let _color     = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
    let _font      = UIFont.systemFontOfSize(17.0)
    let _textColor = UIColor.whiteColor()

    var customBarButton: UIButton!
    var customTitleLabel: UILabel!
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
            customBarButton?.hidden = hideCustomBarButton
        }
    }

    override func loadView() {
        super.loadView()
        completelyTransparentBar()
        navigationBar.backgroundColor = _color
        navigationBar.tintColor = GLOBAL_CUSTOM_COLOR.darkerColor(0.9)
        
        configureCustomStatusBar()
        configureCustomBarButtonIfNeeded()
        configureCustomTitleLabel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fixCustomViewsFrameIfNeeded()
        fixCustomStatusBarFrameIfNeeded()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureCustomBarButtonIfNeeded() {
        guard customBarButton == nil else { return }
        
        customBarButton = UIButton(type: .Custom)
        customBarButton.setImage(UIImage(named: "close")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        customBarButton.tintColor   = UIColor.whiteColor()
        customBarButton.frame.size  = CGSizeMake(25, 25)
        customBarButton.contentMode = .Center
        customBarButton.addTarget(self, action: "dismissViewController", forControlEvents: .TouchUpInside)
        
        navigationBar.addSubview(customBarButton)
        
        hideCustomBarButton = shouldHideCustomBarButton
    }
    
    private func configureCustomStatusBar() {
        
        guard UIDevice.currentDevice().userInterfaceIdiom != .Pad else { return }
        
        customStatusBar = UIView(frame: UIApplication.sharedApplication().statusBarFrame)
        customStatusBar.backgroundColor = _color
        
        view.addSubview(customStatusBar)
    }
    
    private func configureCustomTitleLabel() {
        
        customTitleLabel               = UILabel(frame: CGRectZero)
        customTitleLabel.textAlignment = .Center
        customTitleLabel.textColor     = _textColor
        customTitleLabel.font          = _font
        
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
        customBarButton?.center = navigationBar.center
        customBarButton?.frame.origin.x = 8.0
        customTitleLabel?.sizeToFit()
        customTitleLabel?.center = navigationBar.center
        
        if UIScreen.screenWidth() < UIScreen.screenHeight() && UIDevice.currentDevice().userInterfaceIdiom != .Pad {
            customBarButton?.frame.origin.y -= UIApplication.sharedApplication().statusBarFrame.height
            customTitleLabel?.frame.origin.y -= UIApplication.sharedApplication().statusBarFrame.height
        }
    }

}

extension SettingsNavigationController {
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        
        // Optimized for 6(s) Plus
        if Device.isEqualToScreenSize(Size.Screen5_5Inch) {
            hideCustomBarButton = toInterfaceOrientation.isLandscape
        }
    }
}
