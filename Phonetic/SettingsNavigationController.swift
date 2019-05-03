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


class SettingsNavigationController: UINavigationController {

    let _font      = UIFont.systemFont(ofSize: 17.0)
    let _textColor = UIColor.white

    var configureBeforeDismissing: Closure!
    var customBarButton: UIButton!
    
    fileprivate(set) var customTitleLabel: UILabel!
    fileprivate(set) var customNavBar: UIView!
    
    fileprivate var shouldHideCustomBarButton: Bool {
        // iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        }
        
        // 6(s) Plus or larger iPhones in the future (maybe).
        if Device.size() > .screen4_7Inch {
            return UIApplication.shared.statusBarOrientation.isLandscape
        }
        
        return false
    }
    
    var hideCustomBarButton = false {
        didSet {
            customBarButton?.isHidden = hideCustomBarButton
        }
    }

    override func loadView() {
        super.loadView()
        completelyTransparentBar()
        navigationBar.backgroundColor = GLOBAL_LIGHT_GRAY_COLOR
        navigationBar.tintColor = GLOBAL_CUSTOM_COLOR.darker(0.9)
        
        configureCustomNavBar()
        configureCustomBarButtonIfNeeded()
        configureCustomTitleLabel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func resetToDefaultCustomTitleLabelInterface() {
        customTitleLabel?.font = _font
        customTitleLabel?.textColor = _textColor
    }
    
    func configureCustomBarButtonIfNeeded() {
        
        guard customBarButton == nil else { return }
        
        customBarButton = UIButton(type: .custom)
        customBarButton.setImage(#imageLiteral(resourceName: "close").withRenderingMode(.alwaysTemplate), for: UIControlState())
        customBarButton.tintColor   = UIColor.white
        customBarButton.contentMode = .center
        customBarButton.addTarget(self, action: #selector(customBarButtonDidTap), for: .touchUpInside)
        
        view.addSubview(customBarButton)
        customBarButton.snp.remakeConstraints { (make) in
            make.width.height.equalTo(25)
            make.centerY.equalTo(navigationBar)
            make.left.equalTo(10)
        }
        
        hideCustomBarButton = shouldHideCustomBarButton
    }
    
    @objc fileprivate func customBarButtonDidTap() {
        
        configureBeforeDismissing?()
        
        if let vc = viewControllers.first as? BaseTableViewController {
//            vc.dismissViewController(completion: nil)
            vc.dismiss(animated: true, completion: nil)
        }
    }
    
    fileprivate func configureCustomNavBar() {
        
        guard !UIDevice.current.isPad else { return }
        
        customNavBar = UIView()
//        customNavBar.backgroundColor = GLOBAL_LIGHT_GRAY_COLOR
//        customNavBar.isUserInteractionEnabled = true
//        view.insertSubview(customNavBar, at: 0)
//        customNavBar.snp.makeConstraints { (make) in
//            make.left.bottom.right.equalTo(navigationBar)
//            make.top.equalTo(view)
//        }
    }
    
    fileprivate func configureCustomTitleLabel() {
        
        customTitleLabel               = UILabel()
        customTitleLabel.textAlignment = .center
        customTitleLabel.textColor     = _textColor
        customTitleLabel.font          = _font
        customTitleLabel.sizeToFit()
        navigationBar.addSubview(customTitleLabel)
        customTitleLabel.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
        }
    }

}
