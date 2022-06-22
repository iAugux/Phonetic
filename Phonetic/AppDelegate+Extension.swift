//
//  AppDelegate+Extension.swift
//  Phonetic
//
//  Created by Augus on 1/27/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import ASKit
import Contacts
import UIKit

extension AppDelegate {
    func requestContactsAccess(_ completionHandler: Handler<Bool>? = nil) {
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        switch authStatus {
        case .authorized:
            completionHandler?(true)
        case .denied, .notDetermined:
            contactStore.requestAccess(for: .contacts, completionHandler: { [weak self] access, error in
                guard !access else {
                    DispatchQueue.main.async {
                        completionHandler?(true)
                    }
                    return
                }
                guard authStatus == .denied else { return }
                DispatchQueue.main.async {
                    let title = error?.localizedDescription ?? "" + " !!!"
                    let message = NSLocalizedString("Please allow `Phonetic` to access your Contacts through the Settings.", comment: "UIAlertController message")
                    self?.showAllowContactsAccessMessage(title, message: message)
                }
            })
        default:
            completionHandler?(false)
        }
    }

    private func showAllowContactsAccessMessage(_ title: String, message: String) {
        let okActionTitle = NSLocalizedString("Settings", comment: "UIAlertAction - title")
        let cancelActionTitle = NSLocalizedString("Cancel", comment: "UIAlertAction - title")
        let alertViewController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: okActionTitle, style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString))
        }
        alertViewController.addAction(okAction)
        alertViewController.addAction(cancelAction)
        alertViewController.preferredAction = okAction
        UIApplication.shared.topMostViewController?.present(alertViewController, animated: true, completion: nil)
    }
}
