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
       multiAlerts([info], completionHandler: completionHandler)
    }
    
    func multiAlerts(multiItemsOfInfo: [String], completionHandler: (() -> Void)?) {
        alert(multiItemsOfInfo, loopHandler: nil, completionHandler: completionHandler)
    }
    
    private func alert(multiItemsOfInfo: [String], loopHandler: (() -> Void)?, completionHandler: (() -> Void)?) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            var tempInfoArray = multiItemsOfInfo
            
            guard tempInfoArray.count > 0 else { return }
            
            let alertController = UIAlertController(title: nil, message: tempInfoArray.first, preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: { (_) -> Void in
                
                tempInfoArray.removeFirst()
                
                self.alert(tempInfoArray, loopHandler: loopHandler, completionHandler: nil)
                self.alert(tempInfoArray, loopHandler: { () -> Void in
                    if tempInfoArray.count == 0 {
                        if let completion = completionHandler {
                            completion()
                        }
                    }
                    }, completionHandler: nil)
                
            })
            alertController.addAction(cancelAction)
            UIApplication.topMostViewController()?.presentViewController(alertController, animated: true, completion: nil)
        }
    }

    
}


