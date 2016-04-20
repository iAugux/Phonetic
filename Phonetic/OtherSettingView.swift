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
    
    private var picker: MFMailComposeViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(viewDidTap))
        addGestureRecognizer(recognizer)
    }
    
    internal func viewDidTap() {
        parentViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            
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
        let tweetbotURL = NSURL(string: "tweetbot://iAugux/user_profile/iAugux")
        let twitterURL = NSURL(string: "twitter://user?screen_name=iAugux")
        if UIApplication.sharedApplication().canOpenURL(tweetbotURL!) {
            UIApplication.sharedApplication().openURL(tweetbotURL!)
            return
        }
        if UIApplication.sharedApplication().canOpenURL(twitterURL!) {
            UIApplication.sharedApplication().openURL(twitterURL!)
            return
        }
        
        let safariVC = SFSafariViewController(URL: NSURL(string: "https://twitter.com/iAugux")!)
        safariVC.delegate = self
        UIApplication.topMostViewController?.presentViewController(safariVC, animated: true, completion: {
            UIApplication.sharedApplication().statusBarStyle = .Default
        })
    }
    
    // MARK: - Rate me
    static func RateMe() {
        let appURL = NSURL(string: "https://itunes.apple.com/app/viewContentsUserReviews?id=1078961574")
        if UIApplication.sharedApplication().canOpenURL(appURL!) {
            UIApplication.sharedApplication().openURL(appURL!)
        }
    }
    
    // MARK: - feedback with Mail
    private func sendMail() {
        if MFMailComposeViewController.canSendMail() {
            picker = MFMailComposeViewController()
            picker?.mailComposeDelegate = self
            picker?.setToRecipients(["iAugux@gmail.com"])
            picker?.setSubject("Phonetic Contacts Feedback")
            
            if let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String {
                if let build = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String {
                    let info = "# V \(version) (\(build)), \(Device.version()), iOS \(UIDevice.currentDevice().systemVersion) #\n"
                    picker?.setMessageBody(info, isHTML: true)
                    UIApplication.topMostViewController?.presentViewController(picker!, animated: true, completion: nil)
                }
            }
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true) { () -> Void in
            self.picker = nil
        }
    }
    
}