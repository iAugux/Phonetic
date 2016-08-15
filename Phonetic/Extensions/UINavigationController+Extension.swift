//
//  UINavigationController+Extension.swift
//
//  Created by Augus on 1/30/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


extension UINavigationController {
    
    func completelyTransparentBar() {
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
        view.backgroundColor = UIColor.clear
        navigationBar.backgroundColor = UIColor.clear
    }
    
}
