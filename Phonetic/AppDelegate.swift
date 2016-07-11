//
//  AppDelegate.swift
//  Phonetic
//
//  Created by Augus on 1/27/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit
import Contacts


let appDelegate = UIApplication.shared().delegate as! AppDelegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let contactStore = CNContactStore()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        createShortcutItemsWithIcons()

        application.statusBarStyle = .lightContent
        window?.backgroundColor = UIColor.clear()
        
        // clear icon badge number if needed.
        application.applicationIconBadgeNumber = 0
        
        application.beginBackgroundTask(withName: "showNotification", expirationHandler: nil)

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
                
        // fixes UI bug
        if let rootViewController = window?.rootViewController as? ViewController {
            if !rootViewController.isProcessing {
                rootViewController.progress?.alpha = 0
            }
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        // clear icon badge number
        application.applicationIconBadgeNumber = 0
        
        // fixes UI bugs
        if let rootViewController = window?.rootViewController as? ViewController {
            if !rootViewController.isProcessing {
                UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: { () -> Void in
                    rootViewController.progress?.alpha = 1
                    }, completion: nil)
            } else {
                // replay if needed
                rootViewController.playVideoIfNeeded()
            }
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    
}


extension AppDelegate {
    
    // Detecting touching outside of the popover
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard UIDevice.isPad else { return }
        
        DEBUGLog("Touched Began")
        
        kShouldRepresentAdditionalVC = false
        kShouldRepresentPolyphonicVC = false
    }
    
    // getVisibleViewController
    func getVisibleViewController(_ _rootViewController: UIViewController? = nil) -> UIViewController? {
        
        var rootViewController = _rootViewController
        
        if rootViewController == nil {
            rootViewController = UIApplication.shared().keyWindow?.rootViewController
        }
        
        if rootViewController?.presentedViewController == nil {
            return rootViewController
        }
        
        if let presented = rootViewController?.presentedViewController {

            if let nav = presented as? UINavigationController {
                return nav.viewControllers.last
            }
            
            if let tab = presented as? UITabBarController {
                return tab.selectedViewController
            }
            
            return getVisibleViewController(presented)
        }
        return nil
    }
}

