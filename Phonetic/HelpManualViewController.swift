//
//  HelpManualViewController.swift
//  Phonetic
//
//  Created by Augus on 2/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

class HelpManualViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = .whiteColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        title = NSLocalizedString("Help Manual", comment: "Navigation title")

        if let nav = navigationController as? SettingsNavigationController {
            nav.customTitleLabel?.text = ""
            navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: nav._textColor, NSFontAttributeName: nav._font]
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openSystemSettings(sender: AnyObject) {
//        if let url = NSURL(string: UIApplicationOpenSettingsURLString) {
//            UIApplication.sharedApplication().openURL(url)
//        }
        
        // TODO: - Is it possible to go to the direct destination?
        let str = "prefs:root=ACCOUNT_SETTINGS&path="
        
        if let url = NSURL(string: str) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
}


extension HelpManualViewController {
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        
        guard UIDevice.isPad else { return }
        
        dismissViewController()
    }

}
