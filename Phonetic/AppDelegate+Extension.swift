//
//  AppDelegate+Extension.swift
//  Phonetic
//
//  Created by Augus on 1/27/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit
import Contacts

extension AppDelegate {
    
    func requestAccess() {
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(requestAccessSelector), userInfo: nil, repeats: false)
    }
    
    func requestAccessSelector() {
        requestContactsAccess { (accessGranted) -> Void in
        }
    }
    
    func requestContactsAccess(completionHandler: (accessGranted: Bool) -> Void) {
        let authStatus = CNContactStore.authorizationStatusForEntityType(.Contacts)

        switch authStatus {
            
        case .Authorized:
            completionHandler(accessGranted: true)
        case .Denied, .NotDetermined:
            contactStore.requestAccessForEntityType(.Contacts, completionHandler: { (access, error) -> Void in
                if access {
                    completionHandler(accessGranted: true)
                } else {
                    if authStatus == .Denied {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let title = error!.localizedDescription + " !!!"
                            let message = NSLocalizedString("Please allow `Phonetic` to access your Contacts through the Settings.", comment: "UIAlertController message")
                            self.showAllowContactsAccessMessage(title, message: message)
                        })
                    }
                }
            })
            
        default:
            completionHandler(accessGranted: false)
        }
    }
    
    private func showAllowContactsAccessMessage(title: String, message: String) {
        let okActionTitle = NSLocalizedString("Settings", comment: "UIAlertAction - title")
        let cancelActionTitle = NSLocalizedString("Cancel", comment: "UIAlertAction - title")
        
        let alertViewController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: okActionTitle, style: .Default) { (_) -> Void in
            if let url = NSURL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        
        alertViewController.addAction(okAction)
        alertViewController.addAction(cancelAction)
        UIApplication.topMostViewController?.presentViewController(alertViewController, animated: true, completion: nil)
    }
    
}