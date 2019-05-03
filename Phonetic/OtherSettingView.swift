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

final class OtherSettingView: UIStackView, MFMailComposeViewControllerDelegate, SFSafariViewControllerDelegate {
    private var picker: MFMailComposeViewController!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(viewDidTap))
        addGestureRecognizer(recognizer)
        configureFollowingIcon()
    }
    
    @objc private func viewDidTap() {
        parentViewController?.dismiss(animated: true, completion: {
            // simulate highlight
            for view in self.subviews {
                if let img = view as? UIImageView {
                    img.simulateHighlight()
                    break
                }
            }
            switch self.tag {
            case 0: self.followMe()
            case 1: OtherSettingView.RateMe()
            case 2: self.sendMail() // Feedback
            default: break
            }
        })
    }
    
    private func configureFollowingIcon() {
        let imageName = DetectPreferredLanguage.isSimplifiedChinese ? "weibo" : "twitter"
        let image = UIImage(named: imageName)
        subviews.forEach {
            if $0.tag == 999, let imageView = $0 as? UIImageView { imageView.image = image }
        }
    }
    
    // MARK: - follow me on Twitter or Weibo
    private func followMe() {
        DetectPreferredLanguage.isSimplifiedChinese ? followMeOnWeibo() : followMeOnTwitter()
    }
    
    private func followMeOnTwitter() {
        let tweetbotURL = URL(string: "tweetbot://iAugux/user_profile/iAugux")!
        let twitterURL = URL(string: "twitter://user?screen_name=iAugux")!
        let urls = [tweetbotURL, twitterURL]
        for url in urls {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
                return
            }
        }
        
        let safariVC = SFSafariViewController(url: URL(string: "https://twitter.com/iAugux")!)
        safariVC.delegate = self
        UIApplication.shared.topMostViewController?.present(safariVC, animated: true, completion: nil)
    }
    
    private func followMeOnWeibo() {
        let id = "1778865900"
        /// I love `VVebo`, but... you know... Fuck Sina
        /// What's the url scheme of WeicoPro?
        /// com.weico.weicopro4://???
        /// weico3://???
        let mokeURL = URL(string: "moke:///user?id=" + id)!
        let weiboURL = URL(string: "sinaweibo://userinfo?uid=" + id)!
        let urls = [mokeURL, weiboURL]
        for url in urls {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
                return
            }
        }
        let safariVC = SFSafariViewController(url: URL(string: "http://weibo.com/augusoo7")!)
        safariVC.delegate = self
        UIApplication.shared.topMostViewController?.present(safariVC, animated: true, completion: nil)
    }
    
    // MARK: - Rate me
    static func RateMe() {
        let id = "1078961574"
        let url: URL
        if #available(iOS 11.0, *) {
            url = APP.appStoreURL(with: id)
        } else {
            url = APP.reviewURL(with: id)
        }
        if UIApplication.shared.canOpenURL(url) { UIApplication.shared.openURL(url) }
    }
    
    // MARK: - feedback with Mail
    private func sendMail() {
        guard MFMailComposeViewController.canSendMail() else { return }
        UINavigationBar.appearance().tintColor = GLOBAL_LIGHT_GRAY_COLOR
        picker = MFMailComposeViewController()
        picker.mailComposeDelegate = self
        picker.setToRecipients(["iAugux@gmail.com"])
        picker.setSubject("Phonetic Contacts Feedback")
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else { return }
        guard let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String else { return }
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersionString.replacingOccurrences(of: "Version", with: "iOS").replacingOccurrences(of: "Build ", with: "")
        let info = "# V \(version) (\(build))" + "</br>" +
            "# \(UIDevice.current.hardwareVersion)" + "</br>" +
            "# \(systemVersion)"
        picker.setMessageBody(info, isHTML: true)
        UIApplication.shared.topMostViewController?.present(picker, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) { self.picker = nil }
    }
}

extension UIView {
    fileprivate func simulateHighlight(withMinAlpha alpha: CGFloat = 0.5, completion: ((Bool) -> ())? = nil) {
        UIView.animate(withDuration: 0.1, animations: {
            self.alpha = alpha
        }, completion: { _ in
            UIView.animate(withDuration: 0.1, delay: 0.1, options: [], animations: {
                self.alpha = 1
            }, completion: completion)
        })
    }
}
