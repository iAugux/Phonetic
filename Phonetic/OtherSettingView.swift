//
//  OtherSettingView.swift
//  Phonetic
//
//  Created by Augus on 1/30/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit
import MessageUI
import SafariServices
import Device

class OtherSettingView: UIStackView, MFMailComposeViewControllerDelegate, SFSafariViewControllerDelegate {
    
    private var picker: MFMailComposeViewController!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(viewDidTap))
        addGestureRecognizer(recognizer)
    }
    
    internal func viewDidTap() {
        parentViewController?.dismiss(animated: true, completion: { () -> Void in
            
            // simulate highlight
            for view in self.subviews {
                if let img = view as? UIImageView {
                    img.simulateHighlight()
                    break
                }
            }
            
            switch self.tag {
            case 0: // Twitter
                self.followOnTwitter()
            case 1: // Rate
                OtherSettingView.RateMe()
            case 2: // Feedback
                self.sendMail()
            default: break
            }
        })
    }
    
    // MARK: - follow me on Twitter
    private func followOnTwitter() {
        let tweetbotURL = URL(string: "tweetbot://iAugux/user_profile/iAugux")
        let twitterURL = URL(string: "twitter://user?screen_name=iAugux")
        if UIApplication.shared.canOpenURL(tweetbotURL!) {
            UIApplication.shared.openURL(tweetbotURL!)
            return
        }
        if UIApplication.shared.canOpenURL(twitterURL!) {
            UIApplication.shared.openURL(twitterURL!)
            return
        }
        
        let safariVC = SFSafariViewController(url: URL(string: "https://twitter.com/iAugux")!)
        safariVC.delegate = self
        UIApplication.topMostViewController?.present(safariVC, animated: true, completion: {
            UIApplication.shared.statusBarStyle = .default
        })
    }
    
    // MARK: - Rate me
    static func RateMe() {
        let appURL = URL(string: "https://itunes.apple.com/app/viewContentsUserReviews?id=1078961574")
        if UIApplication.shared.canOpenURL(appURL!) {
            UIApplication.shared.openURL(appURL!)
        }
    }
    
    // MARK: - feedback with Mail
    private func sendMail() {
        guard MFMailComposeViewController.canSendMail() else { return }
        
        picker = MFMailComposeViewController()
        picker.mailComposeDelegate = self
        picker.setToRecipients(["iAugux@gmail.com"])
        picker.setSubject("Phonetic Contacts Feedback")
        
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else { return }
        guard let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String else { return }
        
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersionString.replacingOccurrences(of: "Version", with: "iOS").replacingOccurrences(of: "Build ", with: "")
        
        let info = "# V \(version) (\(build))" + "</br>" +
            "# \(Device.version())" + "</br>" +
            "# \(systemVersion)"
        
        picker.setMessageBody(info, isHTML: true)
        UIApplication.topMostViewController?.present(picker, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) { () -> Void in
            self.picker = nil
        }
    }
    
}
