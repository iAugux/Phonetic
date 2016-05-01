//
//  PageViewController.swift
//  Zoom Contacts
//
//  Created by Augus on 4/30/16.
//  Copyright © 2016 iAugus. All rights reserved.
//


// REFERENCE: https://github.com/jorgecasariego/Walkthroughs


import UIKit


let WorkthroughSB = UIStoryboard(name: "Walkthrough", bundle: nil)

class PageViewController: UIPageViewController {
    
    var maxIndex: Int!
    
    private static let ACCESS_CONTACTS = NSLocalizedString("Access Contacts", comment: "")
    private static let REQUIRE_CONTACTS_PERMISSION = NSLocalizedString("Contacts permission is required.", comment: "")
    
    private let pageImages = ["access_contacts",
                              "push_notification",
                              "tutorial_screenshot",
                              "access_settings",
                              "tutorial_screenshot"]
    
    private let pageHeaders = [ACCESS_CONTACTS,
                               NSLocalizedString("Push Notification", comment: ""),
                               NSLocalizedString("Quick Search", comment: ""),
                               NSLocalizedString("One More Step", comment: ""),
                               NSLocalizedString("Ready to Go", comment: "")]
    
    private let pageDescriptions = [REQUIRE_CONTACTS_PERMISSION,
                                    NSLocalizedString("Once the mission completed, you'll receive Notification.", comment: ""),
                                    NSLocalizedString("Choose a key for Quick Search. Default is「Nickname Key」.", comment: ""),
                                    NSLocalizedString("Tap the Settings icon to configure.", comment: ""),
                                    ""]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        maxIndex = pageHeaders.count - 1
        
        // this class is the page view controller's data source itself
        self.dataSource = self
        
        // create the first walkthrough vc
        if let startWalkThroughViewController = self.viewControllerAtIndex(0) {
            setViewControllers([startWalkThroughViewController], direction: .Forward, animated: true, completion: nil )
        }
    }

    private func nextPageWithIndex(index: Int) {
        if let nextWalkthroughVC = self.viewControllerAtIndex(index + 1) {
            setViewControllers([nextWalkthroughVC], direction: .Forward, animated: true, completion: nil)
        }
    }
    
    private func viewControllerAtIndex(index: Int) -> WalkthroughViewController? {
        
        if index == NSNotFound || index < 0 || index >= self.pageDescriptions.count { return nil }
        
        guard let walkthroughViewController = WorkthroughSB.instantiateViewControllerWithIdentifier(String(WalkthroughViewController)) as? WalkthroughViewController else { return nil }
        
        walkthroughViewController.imageName = pageImages[index]
        walkthroughViewController.headerText = pageHeaders[index]
        walkthroughViewController.descriptionText = pageDescriptions[index]
        walkthroughViewController.index = index
        
        viewControllerDidSetAt(index)

        return walkthroughViewController
    }
    
}


extension PageViewController {
    
    private func viewControllerDidSetAt(index: Int) {
        
        switch index {
        case 0:
            appDelegate.requestContactsAccess({ (accessGranted) in
                if !accessGranted {
                    appDelegate.requestContactsAccess()
                }
            })
            
        case 1:
            executeAfterDelay(0.5, completion: {
                // register user notification settings
                UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil))
            })
            
//        case 2:
            
            
        default: break
        }
    }
    
    
}


// MARK: - UIPageViewControllerDataSource

extension PageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! WalkthroughViewController).index
        index -= 1
        
        return self.viewControllerAtIndex(index)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! WalkthroughViewController).index
        index += 1
        
        return self.viewControllerAtIndex(index)
    }
}
