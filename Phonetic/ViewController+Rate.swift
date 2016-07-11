//
//  ViewController+Rate.swift
//  Phonetic
//
//  Created by Augus on 1/30/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


extension ViewController {
    
    func rateMeInTheSecondTime() {
        
        guard let build = Bundle.main.objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String else { return }

        let rateMe = "kRateMeOnAppStore\(build)"
        let userDefaults = UserDefaults.standard
        
        guard userDefaults.integer(forKey: rateMe) < 3 else { return }    // never alert again
        
        guard userDefaults.integer(forKey: rateMe) != 2 else {
            userDefaults.set(3, forKey: rateMe)
            
            // rate me
            let title = NSLocalizedString("Rate ♡ Phonetic", comment: "alert controller title - rate me")
            let message = NSLocalizedString("If you enjoy using Phonetic Contacts, would you mind taking a moment to rate it? It won't take more than one minute. Thanks a lot!", comment: "alert controller message")
            let rateActionTitle = NSLocalizedString("Rate", comment: "alert action - Rate")
            let cancelActionTitle = NSLocalizedString("No, thanks", comment: "alert action - Cancel")
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let rateAction = UIAlertAction(title: rateActionTitle, style: .default, handler: { (_) -> Void in
                OtherSettingView.RateMe()
            })
            let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel, handler: nil)
            alertController.addAction(rateAction)
            alertController.addAction(cancelAction)
            UIApplication.topMostViewController?.present(alertController, animated: true, completion: nil)
            
            return
        }
        
        switch userDefaults.integer(forKey: rateMe) {
        case 0 :  // means 'nil'
            userDefaults.set(1, forKey: rateMe)
            return
        case 1:
            userDefaults.set(2, forKey: rateMe)
            return
        default: return
        }
        
    }
    
}
