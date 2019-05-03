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
    @objc internal func popoverInfoViewController() {
        popoverPresentViewController(PopoverButton.info)
        hideLabels(true)
    }

    @objc internal func popoverSettingViewController() {
        popoverPresentViewController(PopoverButton.setting)
        hideLabels(true)
    }

    @objc internal func showLabels() {
        hideLabels(false)
    }

    func hideLabels(_ hidden: Bool) {
        guard let label1 = view.viewWithTag(998), let label2 = view.viewWithTag(999) else { return }
        UIView.animate(withDuration: 0.6, delay: 0.1, options: UIView.AnimationOptions(), animations: {
            label1.alpha = hidden ? 0 : 1
            label2.alpha = hidden ? 0 : 1
        }, completion: nil)
    }

    private enum PopoverButton {
        case info
        case setting
    }

    private struct Popover {
        static var popoverContent: UIViewController?
        static var popover: UIPopoverPresentationController?
        static var currentButton: PopoverButton?
        static let preferredContentWith: CGFloat = 220
        private static let preferredContentHeight: CGFloat = 260
        private static let preferredMutableContentHeight = min(345, UIScreen.height * 0.66)
        static let preferredContentSize = CGSize(width: preferredContentWith, height: preferredContentHeight)
        static let preferredMutableContentSize = CGSize(width: preferredContentWith, height: preferredMutableContentHeight)
    }

    // MARK: - fix size of popover view
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if Popover.currentButton == .info {
            // fix popoverContent's size
            Popover.popoverContent?.preferredContentSize = Popover.preferredContentSize
            // fix popover's source location
            Popover.popover?.sourceRect = infoButton.frame
        } else {
            Popover.popoverContent?.preferredContentSize = Popover.preferredMutableContentSize
            Popover.popover?.sourceRect = settingButton.frame
        }

        Popover.popover?.sourceRect.origin.y += 5
        guard let nav = Popover.popoverContent?.navigationController, let button = Popover.currentButton else { return }
        enableToHideBarsOnSwipeIfNeeded(nav, popoverButton: button)
    }

    // MARK: - configure popover controller
    private func popoverPresentViewController(_ button: PopoverButton) {
        var rect: CGRect
        var title: String
        switch button {
        case .info:
            let infoVC = UIStoryboard.Main.instantiateViewController(with: InfoViewController.self)
            Popover.popoverContent = infoVC
            Popover.popoverContent!.preferredContentSize = Popover.preferredContentSize
            Popover.currentButton = .info
            title = NSLocalizedString("About", comment: "navigation item title - About")
            rect = infoButton.frame
        case .setting:
            let settingVC = UIStoryboard.Main.instantiateViewController(with: SettingViewController.self)
            Popover.popoverContent = settingVC
            Popover.popoverContent!.preferredContentSize = Popover.preferredMutableContentSize
            Popover.currentButton = .setting
            title = NSLocalizedString("Settings", comment: "navigation item title - Settings")
            rect = settingButton.frame
        }

        if let popoverContent = Popover.popoverContent {
            let nav = UINavigationController(rootViewController: popoverContent)
            enableToHideBarsOnSwipeIfNeeded(nav, popoverButton: button)
            nav.makeNavBarCompletelyTransparent()
            nav.modalPresentationStyle = .popover
            Popover.popover = nav.popoverPresentationController
            Popover.popover?.backgroundColor = button == .info ? #colorLiteral(red: 0.3013976812, green: 0.3014355302, blue: 0.3013758659, alpha: 1) : #colorLiteral(red: 0.2924501002, green: 0.2924869955, blue: 0.2924288213, alpha: 1)
            Popover.popover?.delegate = self
            Popover.popover?.sourceView = view
            configureCustomNavigationTitle(nav, title: title)
            rect.origin.y += 5
            Popover.popover?.sourceRect = rect
            present(nav, animated: true, completion: nil)
        }
    }

    private func configureCustomNavigationTitle(_ nav: UINavigationController, title: String?) {
        guard title != nil else { return }
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
        titleLabel.textColor = UIColor.white
        titleLabel.sizeToFit()
        nav.navigationBar.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    private func enableToHideBarsOnSwipeIfNeeded(_ nav: UINavigationController, popoverButton: PopoverButton) {
        if popoverButton == .setting {
            nav.hidesBarsOnSwipe = UIDevice.current.isPad ? false : UIApplication.shared.statusBarOrientation.isLandscape
        } else {
            nav.hidesBarsOnSwipe = false
        }
    }

    // MARK: - UIAdaptivePresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    // MARK: - for iPhone 6(s) Plus
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

    override func overrideTraitCollection(forChild childViewController: UIViewController) -> UITraitCollection? {
        // disable default UITraitCollection, fix size of popover view on iPhone 6(s) Plus.
        return nil
    }
}
