//
//  UIEffectView+Ex.swift
//  Phonetic
//
//  Created by Augus on 3/23/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


/// fixes: blur effect not working on early iPad.

//private var xoAssociationKey: UInt8 = 0
//
//extension UIVisualEffectView {
//    
//    private var subview: UIView! {
//        get {
//            return objc_getAssociatedObject(self, &xoAssociationKey) as? UIView
//        }
//        set(newValue) {
//            objc_setAssociatedObject(self, &xoAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
//        }
//    }
//    
//    public override func drawRect(rect: CGRect) {
//        super.drawRect(rect)
//        // Former: Testing on Real Device, it won't affect on Simulator
//        guard !UIDevice.currentDevice().isBlurSupported() || UIAccessibilityIsReduceTransparencyEnabled() else { return }
//        
//        effect = nil
//        subview = UIView(frame: frame)
//        subview.backgroundColor = UIColor(red: 0.498, green: 0.498, blue: 0.498, alpha: 0.626)
//        addSubview(subview)
//    }
//    
//    public override func layoutSubviews() {
//        super.layoutSubviews()
//        subview?.frame = bounds
//    }
//    
//}