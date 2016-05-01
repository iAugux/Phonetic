//
//  CustomSelectedBackgroundView.swift
//  iBBS
//
//  Created by Augus on 10/6/15.
//  Copyright © 2015 iAugus. All rights reserved.
//

import UIKit


class CustomSelectedBackgroundView: UIView {

    override func drawRect(rect: CGRect) {
        let aRef = UIGraphicsGetCurrentContext()
        CGContextSaveGState(aRef)
        let bezierPath = UIBezierPath(roundedRect: rect, cornerRadius: 8.0)
        bezierPath.lineWidth = 8.0
        UIColor.whiteColor().setFill()
        bezierPath.fill()
        CGContextRestoreGState(aRef)
        
    }
}