//
//  UIApplication+Extension.swift
//
//  Created by Augus on 3/1/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


extension UIApplication {
    
    class func initializeInTheFirstTime(completion: (() -> Void)) {
        if !NSUserDefaults.standardUserDefaults().boolForKey("ausHasLaunchedHostAppOnce") {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "ausHasLaunchedHostAppOnce")
            NSUserDefaults.standardUserDefaults().synchronize()
            
            completion()
        }
    }
}