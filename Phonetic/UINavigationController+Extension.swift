//
//  UINavigationController+Extension.swift
//
//  Created by Augus on 1/30/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


extension UINavigationController {
    
    func completelyTransparentBar() {
        navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationBar.shadowImage = UIImage()
        navigationBar.translucent = true
        view.backgroundColor = UIColor.clearColor()
        navigationBar.backgroundColor = UIColor.clearColor()
    }
    
}