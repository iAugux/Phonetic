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
    
    func requestContactsAccess(_ completionHandler: ((accessGranted: Bool) -> Void)? = nil) {
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)

        switch authStatus {
            
        case .authorized:
            completionHandler?(accessGranted: true)
        case .denied, .notDetermined:
            contactStore.requestAccess(for: .contacts, completionHandler: { (access, error) -> Void in
                if access {
                    completionHandler?(accessGranted: true)
                } else {
                    if authStatus == .denied {
                        DispatchQueue.main.async(execute: { () -> Void in
                            let title = error!.localizedDescription + " !!!"
                            let message = NSLocalizedString("Please allow `Phonetic` to access your Contacts through the Settings.", comment: "UIAlertController message")
                            self.showAllowContactsAccessMessage(title, message: message)
                        })
                    }
                }
            })
            
        default:
            completionHandler?(accessGranted: false)
        }
    }
    
    private func showAllowContactsAccessMessage(_ title: String, message: String) {
        let okActionTitle = NSLocalizedString("Settings", comment: "UIAlertAction - title")
        let cancelActionTitle = NSLocalizedString("Cancel", comment: "UIAlertAction - title")
        
        let alertViewController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: okActionTitle, style: .default) { (_) -> Void in
            if let url = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(url)
            }
        }
        
        alertViewController.addAction(okAction)
        alertViewController.addAction(cancelAction)
        UIApplication.topMostViewController?.present(alertViewController, animated: true, completion: nil)
    }
    
}
