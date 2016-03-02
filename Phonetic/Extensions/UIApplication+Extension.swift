//
//  UIApplication+Extension.swift
//
//  Created by Augus on 3/1/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


extension UIApplication {
    
    class func initializeInTheFirstTime(completion: (() -> Void)) {
        UIApplication.initializeInTheFirstTime(nil, completion: completion)
    }
    
    class func initializeInTheFirstTime(key: String?, completion: (() -> Void)) {
        
        let _key = (key == nil) ? "ausHasLaunchedHostAppOnce" : key!
        
        if !NSUserDefaults.standardUserDefaults().boolForKey(_key) {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: _key)
            NSUserDefaults.standardUserDefaults().synchronize()
            
            completion()
        }
    }
    
}