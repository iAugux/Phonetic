//
//  UIApplication+Extension.swift
//
//  Created by Augus on 3/1/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


extension UIApplication {
    
    class func initializeInTheFirstTime(_ completion: (() -> Void)) {
        UIApplication.initializeInTheFirstTime(nil, completion: completion)
    }
    
    class func initializeInTheFirstTime(_ key: String?, completion: (() -> Void)) {
        
        let _key = (key == nil) ? "ausHasLaunchedHostAppOnce" : key!
        
        if !UserDefaults.standard.bool(forKey: _key) {
            UserDefaults.standard.set(true, forKey: _key)
            UserDefaults.standard.synchronize()
            
            completion()
        }
    }
    
}
