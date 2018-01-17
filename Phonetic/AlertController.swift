//
//  AlertController.swift
//  Phonetic
//
//  Created by Augus on 2/3/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

class AlertController {
    
    private static let ok = NSLocalizedString("OK", comment: "")
    
    class func alert(_ title: String = "", message: String = "", actionTitle: String = ok, completionHandler: (() -> Void)?) {
        AlertController.alert(title, message: message, actionTitle: actionTitle, addCancelAction: false, completionHandler: completionHandler, canceledHandler: nil)
       }
    
    class func alertWithCancelAction(_ title: String = "", message: String = "", actionTitle: String = ok, completionHandler: (() -> Void)?, canceledHandler: (() -> Void)?) {
        AlertController.alert(title, message: message, actionTitle: actionTitle, addCancelAction: true, completionHandler: completionHandler, canceledHandler: canceledHandler)
    }
    
    class func multiAlertsWithOptions(_ multiItemsOfInfo: [String], completionHandler: (() -> Void)?) {
        alertWithOptions(multiItemsOfInfo, completionHandler: completionHandler)
    }
    
    private class func alert(_ title: String = "", message: String = "", actionTitle: String = ok, addCancelAction: Bool, completionHandler: (() -> Void)?, canceledHandler: (() -> Void)?) {
        let okAction = UIAlertAction(title: actionTitle, style: .default) { (_) -> Void in
            if let completion = completionHandler {
                completion()
            }
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if addCancelAction {
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (_) -> Void in
                if let handler = canceledHandler {
                    handler()
                }
            }

            alertController.addAction(cancelAction)
        }
        
        alertController.addAction(okAction)
        
        UIApplication.topMostViewController?.present(alertController, animated: true, completion: nil)
    }
    
    private class func alertWithOptions(_ multiItemsOfInfo: [String], completionHandler: (() -> Void)?) {
        DispatchQueue.main.async { () -> Void in
            
            var tempInfoArray = multiItemsOfInfo
            
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) -> Void in
                tempInfoArray.removeAll()
            })
            
            let okAction = UIAlertAction(title: "OK", style: .default, handler: { (_) -> Void in
                
                tempInfoArray.removeFirst()
                
                if tempInfoArray.count == 0 {
                    if let completion = completionHandler {
                        completion()
                    }
                }
                
                self.alertWithOptions(tempInfoArray, completionHandler: {
                    if let completion = completionHandler {
                        completion()
                    }                    
                })
                
            })
            guard tempInfoArray.count > 0 else { return }
            
            let alertController = UIAlertController(title: nil, message: tempInfoArray.first, preferredStyle: .alert)
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            UIApplication.topMostViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    
}


