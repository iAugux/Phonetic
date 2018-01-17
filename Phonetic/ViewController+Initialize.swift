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
        
        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else { return }
        
        UIApplication.initializeInTheFirstTime { () -> Void in
            
            let title = NSLocalizedString("Choose Key for Quick Search", comment: "alert controller title")
            let message = NSLocalizedString("`Nickname Key` is highly recommended. This message is only displayed once! You can also set it later in settings.", comment: "alert controller message")
            let okActionTitle = NSLocalizedString("Go Setting", comment: "alert action title")
            let laterActionTitle = NSLocalizedString("I'll Set it Later", comment: "alert action title")
            let cancelActionTitle = NSLocalizedString("Already Done. Dismiss", comment: "alert action title")
        
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: okActionTitle, style: .default, handler: { (_) -> Void in
                self.goSetting()
            })
            let laterAction = UIAlertAction(title: laterActionTitle,style: .default, handler: nil)
            let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel, handler: nil)

            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            alertController.addAction(laterAction)
            UIApplication.topMostViewController?.present(alertController, animated: true, completion: nil)
        }

    }
    
    private func goSetting() {
        performSegue(withIdentifier: "rootVCPresentAdditionalVC", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "rootVCPresentAdditionalVC" {
            guard let destinationVC = segue.destination as? SettingsNavigationController else { return }
            destinationVC.popoverPresentationController?.sourceRect = settingButton.bounds
            destinationVC.popoverPresentationController?.backgroundColor = kNavigationBarBackgroundColor
        }
    }
    
}



