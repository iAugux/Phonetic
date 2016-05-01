//
//  ViewController+Popover.swift
//  Phonetic
//
//  Created by Augus on 1/30/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit
import SnapKit

// MARK: - Popover view controller even on iPhones
extension ViewController: UIPopoverPresentationControllerDelegate {
    
    internal func popoverInfoViewController() {
        popoverPresentViewController(PopoverButton.Info)
        hideLabels(true)
    }
    
    internal func popoverSettingViewController() {
        popoverPresentViewController(PopoverButton.Setting)
        hideLabels(true)
    }
    
    internal func showLabels() {
        hideLabels(false)
    }
    
    private func hideLabels(hidden: Bool) {
        if let label1 = view.viewWithTag(998), label2 = view.viewWithTag(999) {
            UIView.animateWithDuration(0.6, delay: 0.1, options: .CurveEaseInOut, animations: { () -> Void in
                label1.alpha = hidden ? 0 : 1
                label2.alpha = hidden ? 0 : 1
                
                }, completion: nil)
        }
    }
    
    private enum PopoverButton {
        case Info
        case Setting
    }

    private struct Popover {
        static var popoverContent: UIViewController?
        static var popover: UIPopoverPresentationController?
        static var currentButton: PopoverButton?
        static let preferredContentWith: CGFloat = 220 //min(300, UIScreen.screenWidth() * 0.6)
        
        private static let preferredContentHeight: CGFloat = 260
        private static let preferredMutableContentHeight = min(345, UIScreen.screenHeight() * 0.66)
        
        static let preferredContentSize = CGSizeMake(preferredContentWith, preferredContentHeight)
        static let preferredMutableContentSize = CGSizeMake(preferredContentWith, preferredMutableContentHeight)
    }
    
    // MARK: - fix size of popover view
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
                
        if Popover.currentButton == .Info {
            
            // fix popoverContent's size
            Popover.popoverContent?.preferredContentSize = Popover.preferredContentSize
            
            // fix popover's source location
            Popover.popover?.sourceRect = infoButton.frame
            
        } else {
            Popover.popoverContent?.preferredContentSize = Popover.preferredMutableContentSize
            Popover.popover?.sourceRect = settingButton.frame
        }
        
        Popover.popover?.sourceRect.origin.y += 5
    }
    
    // MARK: - configure popover controller
    private func popoverPresentViewController(button: PopoverButton) {
        var rect: CGRect
        var title: String
        
        switch button {
        case .Info:
            guard let infoVC = UIStoryboard.Main.instantiateViewControllerWithIdentifier(String(InfoViewController)) as? InfoViewController else { return }
            Popover.popoverContent = infoVC
            Popover.popoverContent!.preferredContentSize = Popover.preferredContentSize
            
            Popover.currentButton = .Info
            title = NSLocalizedString("About", comment: "navigation item title - About")
            rect = infoButton.frame
            
        case .Setting:
            guard let settingVC = UIStoryboard.Main.instantiateViewControllerWithIdentifier(String(SettingViewController)) as? SettingViewController else { return }
            Popover.popoverContent = settingVC
            Popover.popoverContent!.preferredContentSize = Popover.preferredMutableContentSize
            
            Popover.currentButton = .Setting
            title = NSLocalizedString("Settings", comment: "navigation item title - Settings")
            rect = settingButton.frame
        }
        
        if let popoverContent = Popover.popoverContent {
            
            let nav = UINavigationController(rootViewController: popoverContent)
            nav.completelyTransparentBar()
            nav.hidesBarsOnSwipe = true
            nav.modalPresentationStyle = .Popover
            Popover.popover = nav.popoverPresentationController
            Popover.popover?.backgroundColor = kNavigationBarBackgroundColor
            Popover.popover?.delegate = self
            Popover.popover?.sourceView = view

            configureCustomNavigationTitle(nav, title: title)
            
            rect.origin.y += 5
            Popover.popover?.sourceRect = rect
            
            presentViewController(nav, animated: true, completion: nil)
        }
    }
    
    private func configureCustomNavigationTitle(nav: UINavigationController, title: String?) {
        
        guard title != nil else { return }
        
        let titleLabel              = UILabel()
        titleLabel.text             = title
        titleLabel.textAlignment    = .Center
        titleLabel.font             = UIFont.boldSystemFontOfSize(17.0)
        titleLabel.textColor        = UIColor.whiteColor()
        titleLabel.sizeToFit()
        nav.navigationBar.addSubview(titleLabel)
        titleLabel.snp_makeConstraints { (make) in
            make.center.equalTo(nav.navigationBar)
        }
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
    // MARK: - for iPhone 6(s) Plus
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .None
    }
    
    override func overrideTraitCollectionForChildViewController(childViewController: UIViewController) -> UITraitCollection? {
        // disable default UITraitCollection, fix size of popover view on iPhone 6(s) Plus.
        return nil
    }
    

}