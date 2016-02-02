//
//  InfoAlertController.swift
//  Phonetic
//
//  Created by Augus on 2/3/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import CoreAudioKit



class InfoAlertController {
    
    func alert(info: String) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            let alertController = UIAlertController(title: nil, message: info, preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            UIApplication.topMostViewController()?.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
}


