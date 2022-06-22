//  ASKit.swift
//  Created by Augus <iAugux@gmail.com>.
//  Copyright © 2015-2020 iAugus. All rights reserved.

import UIKit

// MARK: UIResponder
private var _currentFirstResponder: UIResponder?
extension UIResponder {
    public var currentFirstResponder: UIResponder? {
        _currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(UIResponder.findFirstResponder(_:)), to: nil, from: nil, for: nil)
        return _currentFirstResponder
    }

    @objc private func findFirstResponder(_ sender: Any) {
        _currentFirstResponder = self
    }
}

extension UIApplication {
    var compatibleKeyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .map { $0 as? UIWindowScene }
                .compactMap { $0 }
                .first?.windows
                .filter(\.isKeyWindow).first
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}

public extension UIApplication {
    /// The toppest view controller of presenting view controller
    var topMostViewController: UIViewController? {
        var topController = UIApplication.shared.compatibleKeyWindow?.rootViewController
        while topController?.presentedViewController != nil { topController = topController?.presentedViewController }
        return topController
    }

    var topMostNavigationController: UINavigationController? {
        guard let top = topMostViewController else { return nil }
        return (top as? UINavigationController) ?? top.navigationController
    }
}

// MARK: UIViewController Extensions
public extension UIViewController {
    var statusBarFrame: CGRect {
        let compatibleKeyWindow: UIWindow? = {
            if #available(iOS 13.0, *) {
                return UIApplication.shared.connectedScenes
                    .map { $0 as? UIWindowScene }
                    .compactMap { $0 }
                    .first?.windows
                    .filter(\.isKeyWindow).first
            } else {
                return UIApplication.shared.keyWindow
            }
        }()
        guard let window = compatibleKeyWindow else {
            ASWarn("Window is nil")
            return .zero
        }
        if #available(iOS 13.0, *) {
            return window.windowScene?.statusBarManager?.statusBarFrame ?? .zero
        } else {
            return window.convert(UIApplication.shared.statusBarFrame, to: view)
        }
    }

    /// Top bar height (status bar + navigation bar)
    var topBarHeight: CGFloat {
        guard let window = UIApplication.shared.compatibleKeyWindow else { return 0 }
        let navBarHeight: CGFloat = {
            guard let bar = navigationController?.navigationBar else { return 0 }
            return window.convert(bar.frame, to: view).height
        }()
        let statusBarHeight = window.convert(statusBarFrame, to: view).height
        return statusBarHeight + navBarHeight
    }
}

// MARK: - Current View Controller
extension UIViewController {
    public static var current: UIViewController {
        if #available(iOS 13.0, *) {
            guard let scene = (UIApplication.shared.connectedScenes.filter { $0.activationState == .foregroundActive }.compactMap { $0 as? UIWindowScene }).first else {
                ASWarn("Can't find the active sence")
                return UIViewController()
            }
            guard let vc = (scene.delegate as? UIWindowSceneDelegate)?.window??.rootViewController else {
                ASWarn("Can't find the window")
                return UIViewController()
            }
            return vc.findBestViewController()
        } else {
            guard let rootVC = UIApplication.shared.delegate?.window??.rootViewController else { fatalError("Unable to find the root view controller") }
            return rootVC.findBestViewController()
        }
    }

    private func findBestViewController() -> UIViewController {
        if let vc = presentedViewController {
            // returns presented view controller
            return vc
        } else if let vc = self as? UISplitViewController {
            // returns right hand side
            return vc.viewControllers.last ?? vc
        } else if let vc = self as? UINavigationController {
            // returns top view controller
            return vc.topViewController ?? vc
        } else if let vc = self as? UITabBarController {
            // returns visible view
            return vc.selectedViewController ?? vc
        } else {
            return self
        }
    }
}
