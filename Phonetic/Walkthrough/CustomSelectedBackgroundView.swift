//
//  CustomSelectedBackgroundView.swift
//  iBBS
//
//  Created by Augus on 10/6/15.
//  Copyright © 2015 iAugus. All rights reserved.
//

import UIKit

final class CustomSelectedBackgroundView: UIView {
    override func draw(_ rect: CGRect) {
        let aRef = UIGraphicsGetCurrentContext()
        aRef?.saveGState()
        let bezierPath = UIBezierPath(roundedRect: rect, cornerRadius: 8.0)
        bezierPath.lineWidth = 8.0
        UIColor.white.setFill()
        bezierPath.fill()
        aRef?.restoreGState()
    }
}
