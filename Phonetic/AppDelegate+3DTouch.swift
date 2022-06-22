//
//  AppDelegate+3DTouch.swift
//  Phonetic
//
//  Created by Augus on 4/2/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

extension AppDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        let host = url.host
        if host ~= `Type`.execute.rawValue {
            execute()
            UIApplication.shared.perform(#selector(URLSessionTask.suspend))
        } else if host ~= `Type`.rollback.rawValue {
            rollback()
        }
        return true
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        // react to shortcut item selections
        debugPrint("A shortcut item was pressed. It was ", shortcutItem.localizedTitle)
        switch shortcutItem.type {
        case Type.execute.rawValue: execute()
        case Type.rollback.rawValue: rollback()
        default: return
        }
    }

    private enum `Type`: String {
        case execute
        case rollback
    }

    // MARK: Springboard Shortcut Items (dynamic)
    func createShortcutItemsWithIcons() {
        let executeIcon = UIApplicationShortcutIcon(type: .add)
        let rollbackIcon: UIApplicationShortcutIcon = {
            if #available(iOS 13.0, *) {
                return UIApplicationShortcutIcon(systemImageName: "gobackward")
            } else {
                return UIApplicationShortcutIcon(templateImageName: "rollback_3d")
            }
        }()
        let executeItemTitle = NSLocalizedString("Add Phonetic Keys", comment: "")
        let rollbackItemTitle = NSLocalizedString("Clean Contacts Keys", comment: "")
        // create dynamic shortcut items
        let executeItem = UIMutableApplicationShortcutItem(type: Type.execute.rawValue, localizedTitle: executeItemTitle, localizedSubtitle: nil, icon: executeIcon, userInfo: nil)
        let rollbackItem = UIMutableApplicationShortcutItem(type: Type.rollback.rawValue, localizedTitle: rollbackItemTitle, localizedSubtitle: nil, icon: rollbackIcon, userInfo: nil)
        // add all items to an array
        let items = [executeItem, rollbackItem]
        UIApplication.shared.shortcutItems = items
    }

    // MARK: - Actions
    private func execute() {
        viewController?.execute()
    }

    private func rollback() {
        viewController?.clean()
    }

    private var viewController: ViewController? {
        // ensure root vc is presenting.
        window?.rootViewController?.presentedViewController?.dismissWithoutAnimation()
        return window?.rootViewController as? ViewController
    }
}
