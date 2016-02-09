//
//  UIButton+Extension.swift
//
//  Created by Augus on 2/6/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit



extension UIButton {
    
    
    override public func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        
        let minimalWidthAndHeight: CGFloat = 60
        
        let buttonSize = frame.size
        let widthToAdd = (minimalWidthAndHeight - buttonSize.width > 0) ? minimalWidthAndHeight - buttonSize.width : 0
        let heightToAdd = (minimalWidthAndHeight - buttonSize.height > 0) ? minimalWidthAndHeight - buttonSize.height : 0
        let largerFrame = CGRect(x: 0-(widthToAdd / 2), y: 0-(heightToAdd / 2), width: buttonSize.width + widthToAdd, height: buttonSize.height + heightToAdd)
        return CGRectContainsPoint(largerFrame, point) ? self : nil
    }
    
}