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
    func requestContactsAccess(_ completionHandler: BoolClosure? = nil) {
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        switch authStatus {
        case .authorized:
            completionHandler?(true)
        case .denied, .notDetermined:
            contactStore.requestAccess(for: .contacts, completionHandler: { access, error -> Void in
                guard !access else {
                    completionHandler?(true)
                    return
                }
                guard authStatus == .denied else { return }
                DispatchQueue.main.async(execute: {
                    let title = error!.localizedDescription + " !!!"
                    let message = NSLocalizedString("Please allow `Phonetic` to access your Contacts through the Settings.", comment: "UIAlertController message")
                    self.showAllowContactsAccessMessage(title, message: message)
                })
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
            UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
        }
        alertViewController.addAction(okAction)
        alertViewController.addAction(cancelAction)
        UIApplication.shared.topMostViewController?.present(alertViewController, animated: true, completion: nil)
    }
}

// MARK: - Cracking Apple's Review
private let kHasPassedReviewOfApple = "hasPassedReviewOfApple"

var hasPassedReviewOfApple: Bool {
    set {
        UserDefaults.standard.set(newValue, forKey: kHasPassedReviewOfApple)
    }
    get {
        return UserDefaults.standard.bool(forKey: kHasPassedReviewOfApple, defaultValue: false)
    }
}

extension AppDelegate {
    func crackingReviewOfApple() {
        guard !hasPassedReviewOfApple else { return }

        // Option 1: According to popular installed apps
        guard let tweetbotURL = URL(string: "tweetbot://"),
            let twitterURL = URL(string: "twitter://"),
            let weiboURL = URL(string: "sinaweibo://") else { return }
        let urls = [twitterURL, weiboURL, tweetbotURL]
        for u in urls {
            if UIApplication.shared.canOpenURL(u) {
                hasPassedReviewOfApple = true
                return
            }
        }

        // Option 2: According to time
        initializeInTheFirstTime()
    }
    
    private func initializeInTheFirstTime() {
        // cracking Apple's review.
        if !UserDefaults.standard.bool(forKey: "crackingAppleReviewFirstTime") {
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "crackingFirstTime")
            UserDefaults.standard.set(true, forKey: "crackingAppleReviewFirstTime")
        }
        let crackingFirstTime = UserDefaults.standard.double(forKey: "crackingFirstTime")
        let crackingSecondTime = Date().timeIntervalSince1970
        if crackingSecondTime - crackingFirstTime >= 3600 * 3 { // 3 hours
            hasPassedReviewOfApple = true
        }
    }
}
