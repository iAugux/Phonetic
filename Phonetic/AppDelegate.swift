//
//  AppDelegate.swift
//  Phonetic
//
//  Created by Augus on 1/27/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import ASKit
import Components
import Contacts
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let contactStore = CNContactStore()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        createShortcutItemsWithIcons()
        window?.tintColor = .vividColor
        // clear icon badge number if needed.
        application.applicationIconBadgeNumber = 0
        application.beginBackgroundTask(withName: "showNotification", expirationHandler: nil)
        UISwitch.appearance().onTintColor = .vividColor
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        ARSLineProgress.shown ? ARSLineProgress.hide() : ()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // clear icon badge number
        application.applicationIconBadgeNumber = 0
        guard let rootViewController = window?.rootViewController as? ViewController else { return }
        // replay if needed
        rootViewController.isProcessing ? rootViewController.playAnimations() : ()
    }
}

extension AppDelegate {
    // Detecting touching outside of the popover
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard UIDevice.current.isPad else { return }
        ASLog("Touched Began")
        kShouldRepresentPolyphonicVC = false
    }
}
