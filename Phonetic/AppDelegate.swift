//
//  AppDelegate.swift
//  Phonetic
//
//  Created by Augus on 1/27/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit
import Contacts
import Components

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let contactStore = CNContactStore()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        createShortcutItemsWithIcons()
        window?.tintColor = GLOBAL_CUSTOM_COLOR
        // clear icon badge number if needed.
        application.applicationIconBadgeNumber = 0
        application.beginBackgroundTask(withName: "showNotification", expirationHandler: nil)
        UISwitch.appearance().onTintColor = GLOBAL_CUSTOM_COLOR
        UINavigationBar.appearance().backIndicatorImage = #imageLiteral(resourceName: "Back")
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = #imageLiteral(resourceName: "Back")
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
        rootViewController.isProcessing ? rootViewController.playVideoIfNeeded() : ()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        crackingReviewOfApple()
    }
}

extension AppDelegate {
    // Detecting touching outside of the popover
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard UIDevice.current.isPad else { return }
        asLog("Touched Began")
        kShouldRepresentPolyphonicVC = false
    }
}
