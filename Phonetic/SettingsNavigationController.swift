//
//  SettingsNavigationController.swift
//  Phonetic
//
//  Created by Augus on 2/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit
import Device
import SnapKit


let kNavigationBarBackgroundColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)

class SettingsNavigationController: UINavigationController {

    let _font      = UIFont.systemFontOfSize(17.0)
    let _textColor = UIColor.whiteColor()

    var customBarButton: UIButton!
    private(set) var customTitleLabel: UILabel!
    private var customNavBar: UIView!
    
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
        navigationBar.backgroundColor = kNavigationBarBackgroundColor
        navigationBar.tintColor = GLOBAL_CUSTOM_COLOR.darkerColor(0.9)
        
        configureCustomNavBar()
        configureCustomBarButtonIfNeeded()
        configureCustomTitleLabel()
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
        customBarButton.contentMode = .Center
        customBarButton.addTarget(self, action: #selector(customBarButtonDidTap), forControlEvents: .TouchUpInside)
        
        view.addSubview(customBarButton)
        customBarButton.snp_remakeConstraints { (make) in
            make.width.height.equalTo(25)
            make.centerY.equalTo(navigationBar)
            make.left.equalTo(8)
        }
        
        hideCustomBarButton = shouldHideCustomBarButton
    }
    
    @objc private func customBarButtonDidTap() {
        if let vc = viewControllers.first as? BaseTableViewController {
            vc.dismissViewController(completion: nil)
        }
    }
    
    private func configureCustomNavBar() {
        
        guard !UIDevice.isPad else { return }
        
        customNavBar = UIView()
        customNavBar.backgroundColor = kNavigationBarBackgroundColor
        customNavBar.userInteractionEnabled = false
        navigationBar.addSubview(customNavBar)
        customNavBar.snp_makeConstraints { (make) in
            make.left.bottom.right.equalTo(navigationBar)
            make.top.equalTo(view)
        }
    }
    
    private func configureCustomTitleLabel() {
        
        customTitleLabel               = UILabel()
        customTitleLabel.textAlignment = .Center
        customTitleLabel.textColor     = _textColor
        customTitleLabel.font          = _font
        customTitleLabel.sizeToFit()
        navigationBar.addSubview(customTitleLabel)
        customTitleLabel.snp_makeConstraints { (make) in
            make.centerX.centerY.equalTo(navigationBar)
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
