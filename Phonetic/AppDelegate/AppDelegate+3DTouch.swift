// Created by Augus on 4/2/16
// Copyright © 2016 Augus <iAugux@gmail.com>

import UIKit

extension AppDelegate {
    func handleURL(_ url: URL) -> Bool {
        AppState.shared.handleOpenURL(url) {
            if url.host?.lowercased() == Type.execute.rawValue {
                UIApplication.shared.perform(#selector(URLSessionTask.suspend))
            }
        }
    }

    func handleShortcut(_ shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        debugPrint("A shortcut item was pressed. It was ", shortcutItem.localizedTitle)
        let handled = AppState.shared.handleShortcut(shortcutItem)
        completionHandler(handled)
    }

    private enum `Type`: String {
        case execute
        case rollback
    }

    // MARK: Springboard Shortcut Items (dynamic)
    func createShortcutItemsWithIcons() {
        let executeIcon = UIApplicationShortcutIcon(type: .add)
        let rollbackIcon = UIApplicationShortcutIcon(systemImageName: "gobackward")
        let executeItemTitle = String(localized: "Add Pinyin")
        let rollbackItemTitle = String(localized: "Clear Contact Fields")
        // create dynamic shortcut items
        let executeItem = UIMutableApplicationShortcutItem(type: Type.execute.rawValue, localizedTitle: executeItemTitle, localizedSubtitle: nil, icon: executeIcon, userInfo: nil)
        let rollbackItem = UIMutableApplicationShortcutItem(type: Type.rollback.rawValue, localizedTitle: rollbackItemTitle, localizedSubtitle: nil, icon: rollbackIcon, userInfo: nil)
        // add all items to an array
        let items = [executeItem, rollbackItem]
        UIApplication.shared.shortcutItems = items
    }
}
