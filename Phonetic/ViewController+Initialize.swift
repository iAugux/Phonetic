//
//  ViewController+Initialize.swift
//  Phonetic
//
//  Created by Augus on 3/1/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit
import Contacts


extension ViewController {
    
    func alertToChooseQuickSearchKeyIfNeeded() {
        
        guard CNContactStore.authorizationStatusForEntityType(.Contacts) == .Authorized else { return }
        
        UIApplication.initializeInTheFirstTime { () -> Void in
            
            let title = NSLocalizedString("Choose Key for Quick Search", comment: "alert controller title")
            let message = NSLocalizedString("`Nickname Key` is highly recommended. This message is only displayed once! You can also set it later in settings.", comment: "alert controller message")
            let okActionTitle = NSLocalizedString("Go Setting", comment: "alert action title")
            let laterActionTitle = NSLocalizedString("I'll Set it Later", comment: "alert action title")
            let cancelActionTitle = NSLocalizedString("Already Done. Dismiss", comment: "alert action title")
        
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            let okAction = UIAlertAction(title: okActionTitle, style: .Default, handler: { (_) -> Void in
                self.goSetting()
            })
            let laterAction = UIAlertAction(title: laterActionTitle,style: .Default, handler: nil)
            let cancelAction = UIAlertAction(title: cancelActionTitle, style: .Cancel, handler: nil)

            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            alertController.addAction(laterAction)
            UIApplication.topMostViewController?.presentViewController(alertController, animated: true, completion: nil)
        }

    }
    
    private func goSetting() {
        performSegueWithIdentifier("rootVCPresentAdditionalVC", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "rootVCPresentAdditionalVC" {
            guard let destinationVC = segue.destinationViewController as? SettingsNavigationController else { return }
            destinationVC.popoverPresentationController?.sourceRect = settingButton.bounds
            destinationVC.popoverPresentationController?.backgroundColor = kNavigationBarBackgroundColor
        }
    }
    
}



