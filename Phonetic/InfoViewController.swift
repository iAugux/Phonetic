//
//  InfoViewController.swift
//  Phonetic
//
//  Created by Augus on 1/29/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit
import SafariServices

class InfoViewController: UIViewController, SFSafariViewControllerDelegate {

    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var github: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureGithubImageView()
        configureVersionLabel()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: Notification.Name(rawValue: kVCWillDisappearNotification), object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func configureGithubImageView() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(checkOnGithub))
        github.addGestureRecognizer(recognizer)
    }
    
    private func configureVersionLabel() {
        if let version = Bundle.main.objectForInfoDictionaryKey("CFBundleShortVersionString") as? String {
            if let build = Bundle.main.objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String {
                versionLabel.text = "Version \(version) (\(build))"
            }
        }
    }
    
    func checkOnGithub() {
        
        dismiss(animated: true) { () -> Void in
            let safariVC = SFSafariViewController(url: URL(string: "https://github.com/iAugux/Phonetic")!)
            safariVC.delegate = self
            UIApplication.topMostViewController?.present(safariVC, animated: true, completion: {
                UIApplication.shared().statusBarStyle = .default
            })
        }
    }

}
