//
//  AlertController.swift
//  Phonetic
//
//  Created by Augus on 2/3/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import CoreAudioKit



class AlertController {
    
    func alert(info: String, completionHandler: (() -> Void)?) {
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) -> Void in
            if let completion = completionHandler {
                completion()
            }
        }
        
        let alertController = UIAlertController(title: nil, message: info, preferredStyle: .Alert)
        alertController.addAction(cancelAction)
        UIApplication.topMostViewController()?.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func multiAlertsWithOptions(multiItemsOfInfo: [String], completionHandler: (() -> Void)?) {
        alertWithOptions(multiItemsOfInfo, completionHandler: completionHandler)
    }
    
    private func alertWithOptions(multiItemsOfInfo: [String], completionHandler: (() -> Void)?) {
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


