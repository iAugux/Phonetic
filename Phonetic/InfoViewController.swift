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
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().postNotificationName(kVCWillDisappearNotification, object: nil)
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
        if let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String {
            if let build = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String {
                versionLabel.text = "Version \(version) (\(build))"
            }
        }
    }
    
    func checkOnGithub() {
        
        dismissViewControllerAnimated(true) { () -> Void in
            let safariVC = SFSafariViewController(URL: NSURL(string: "https://github.com/iAugux/Phonetic")!)
            safariVC.delegate = self
            UIApplication.topMostViewController?.presentViewController(safariVC, animated: true, completion: {
                UIApplication.sharedApplication().statusBarStyle = .Default
            })
        }
    }

}
