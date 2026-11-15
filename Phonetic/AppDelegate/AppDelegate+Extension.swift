// Created by Augus on 1/27/16
// Copyright © 2016 Augus <iAugux@gmail.com>

import Contacts
import UIKit

extension AppDelegate {
    func requestContactsAccess() async -> Bool {
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        switch authStatus {
        case .authorized:
            return true
        case .notDetermined:
            return await (try? contactStore.requestAccess(for: .contacts)) ?? false
        case .denied:
            showAllowContactsAccessMessage(String(localized: "Contacts Access Needed"), message: String(localized: "Allow Phonetic to access your contacts in Settings to add pinyin and edit contact fields."))
            return false
        default:
            if #available(iOS 18.0, *), authStatus == .limited {
                return true
            } else {
                return false
            }
        }
    }

    private func showAllowContactsAccessMessage(_ title: String, message: String) {
        let okActionTitle = String(localized: "Settings")
        let cancelActionTitle = String(localized: "Cancel")
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
