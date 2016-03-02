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
    
    class func alert(title title: String = "", message: String = "", actionTitle: String = ok, completionHandler: (() -> Void)?) {
        let okAction = UIAlertAction(title: actionTitle, style: .Cancel) { (_) -> Void in
            if let completion = completionHandler {
                completion()
            }
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(okAction)
        UIApplication.topMostViewController()?.presentViewController(alertController, animated: true, completion: nil)
    }
    
    class func multiAlertsWithOptions(multiItemsOfInfo: [String], completionHandler: (() -> Void)?) {
        alertWithOptions(multiItemsOfInfo, completionHandler: completionHandler)
    }
    
    private class func alertWithOptions(multiItemsOfInfo: [String], completionHandler: (() -> Void)?) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            var tempInfoArray = multiItemsOfInfo
            
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { (_) -> Void in
                tempInfoArray.removeAll()
            })
            
            let okAction = UIAlertAction(title: "OK", style: .Default, handler: { (_) -> Void in
                
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
            
            let alertController = UIAlertController(title: nil, message: tempInfoArray.first, preferredStyle: .Alert)
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            UIApplication.topMostViewController()?.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    
}


