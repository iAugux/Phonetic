//
//  ViewController+Rate.swift
//  Phonetic
//
//  Created by Augus on 1/30/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


extension ViewController {
    
    func rateMeInTheThirdTime() {
        
        guard let build = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String else { return }

        let rateMe = "kRateMeOnAppStore\(build)"
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        guard userDefaults.integerForKey(rateMe) < 4 else { return }    // never alert again
        
        guard userDefaults.integerForKey(rateMe) != 3 else {
            userDefaults.setInteger(4, forKey: rateMe)
            
            // rate me
            let title = NSLocalizedString("Rate ♡ Me", comment: "alert view controller title - rate me")
            let message = NSLocalizedString("If you enjoy Phonetic Contacts, please take one minute to rate me in the App Store. Thanks a lot!", comment: "alert view controller message")
            let rateActionTitle = NSLocalizedString("Rate", comment: "alert action - Rate")
            let cancelActionTitle = NSLocalizedString("No, thanks!", comment: "alert action - Cancel")
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            let rateAction = UIAlertAction(title: rateActionTitle, style: .Default, handler: { (_) -> Void in
                OtherSettingView.RateMe()
            })
            let cancelAction = UIAlertAction(title: cancelActionTitle, style: .Cancel, handler: nil)
            alertController.addAction(rateAction)
            alertController.addAction(cancelAction)
            UIApplication.topMostViewController()?.presentViewController(alertController, animated: true, completion: nil)
            
            return
        }
        
        switch userDefaults.integerForKey(rateMe) {
        case 0 :  // means 'nil'
            userDefaults.setInteger(1, forKey: rateMe)
            return
        case 1:
            userDefaults.setInteger(2, forKey: rateMe)
            return
        case 2:
            userDefaults.setInteger(3, forKey: rateMe)
            return
        default: return
        }
        
    }
    
}