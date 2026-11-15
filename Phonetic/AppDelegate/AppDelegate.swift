// Created by Augus on 1/27/16
// Copyright © 2016 Augus <iAugux@gmail.com>

import Contacts
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    private static var _shared: AppDelegate?
    static var shared: AppDelegate {
        if let instance = _shared {
            return instance
        }
        let newInstance = AppDelegate()
        _shared = newInstance
        return newInstance
    }

    var window: UIWindow?
    let contactStore = CNContactStore()

    override init() {
        super.init()
        if AppDelegate._shared == nil {
            AppDelegate._shared = self
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        createShortcutItemsWithIcons()
        AppBadge.shared.setCount(0)
        application.beginBackgroundTask(withName: "showNotification", expirationHandler: nil)
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}
