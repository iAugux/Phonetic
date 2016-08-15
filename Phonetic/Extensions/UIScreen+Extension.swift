//
//  UIScreen+Extension.swift
//
//  Created by Augus on 9/8/15.
//  Copyright © 2015 iAugus. All rights reserved.
//

import UIKit

extension UIScreen {
    class func screenWidth() -> CGFloat {
        return UIScreen.main.bounds.width
    }
    
    class func screenHeight() -> CGFloat {
        return UIScreen.main.bounds.height
    }
}
