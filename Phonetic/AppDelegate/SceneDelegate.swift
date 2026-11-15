// Created by Augus on 9/28/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var savedShortcutItem: UIApplicationShortcutItem?
    private var savedURL: URL?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let shortcutItem = connectionOptions.shortcutItem {
            savedShortcutItem = shortcutItem
        } else if let url = connectionOptions.urlContexts.first?.url {
            savedURL = url
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        AppBadge.shared.setCount(0)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        if let shortcutItem = savedShortcutItem {
            savedShortcutItem = nil
            Task { @MainActor [weak self] in
                self?.handleShortcutItem(shortcutItem)
            }
        } else if let url = savedURL {
            savedURL = nil
            Task { @MainActor [weak self] in
                _ = self?.handleOpenURL(url)
            }
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        savedURL = nil
        guard let url = URLContexts.first?.url else { return }
        _ = handleOpenURL(url)
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        savedShortcutItem = nil
        handleShortcutItem(shortcutItem, completionHandler: completionHandler)
    }

    private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem, completionHandler: ((Bool) -> Void)? = nil) {
        AppDelegate.shared.handleShortcut(
            shortcutItem,
            completionHandler: completionHandler ?? { _ in }
        )
    }

    private func handleOpenURL(_ url: URL) -> Bool {
        AppDelegate.shared.handleURL(url)
    }
}
