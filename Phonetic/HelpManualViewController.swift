//
//  HelpManualViewController.swift
//  Phonetic
//
//  Created by Augus on 2/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

class HelpManualViewController: UIViewController {
    
    @IBOutlet private weak var settingButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = .whiteColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        guard let nav = navigationController as? SettingsNavigationController else { return }
        
        let title = NSLocalizedString("Help Manual", comment: "Navigation title")
        nav.customTitleLabel?.text = title
        nav.customTitleLabel?.font = UIFont.systemFontOfSize(17)
        nav.customTitleLabel?.textColor = UIColor.whiteColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        settingButton.twinkling(0.6, minAlpha: 0.3, maxAlpha: 1)
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
