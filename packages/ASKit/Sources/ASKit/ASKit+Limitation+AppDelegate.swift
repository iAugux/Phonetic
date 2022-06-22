//  ASKit.swift
//  Created by Augus <iAugux@gmail.com>.
//  Copyright © 2015-2019 iAugus. All rights reserved.

import UIKit

public extension UIApplicationDelegate {
    static var shared: Self { return UIApplication.shared.delegate as! Self }
}

public extension UIApplicationDelegate {
    func visibleViewController(rootViewController: UIViewController? = nil) -> UIViewController? {
        guard let rootViewController = rootViewController ?? UIApplication.shared.compatibleKeyWindow?.rootViewController else { return nil }
        guard let presented = rootViewController.presentedViewController else { return rootViewController }
        if let nav = presented as? UINavigationController { return nav.viewControllers.last }
        if let tab = presented as? UITabBarController { return tab.selectedViewController }
        return visibleViewController(rootViewController: presented)
    }
}
