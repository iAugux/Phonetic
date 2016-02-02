//
//  GradientView.swift
//  Phonetic
//
//  Created by Augus on 1/30/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

class GradientView: UIView {
    
    private var gradient: CAGradientLayer!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        backgroundColor = UIColor.clearColor()
        addBlurEffect()
//        configureGradientView(UIScreen.mainScreen().bounds)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if gradient == nil {
//            configureGradientView(frame)
        }
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        gradient?.frame = UIScreen.mainScreen().bounds
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()  // redraw view after rotating.        
    }
    
    private func configureGradientView(frame: CGRect) {
        backgroundColor = UIColor.clearColor()
        
        gradient        = CAGradientLayer()
        gradient.frame  = frame
        gradient.colors = [UIColor(red:0.4256, green:0.6905, blue:0.99, alpha:0.1).CGColor,
            UIColor(red:0.279, green:0.279, blue:0.279, alpha:0.1).CGColor]
        layer.insertSublayer(gradient, atIndex: 1)
    }
    
    private func addBlurEffect() {
        let bgImageView = UIImageView(image: UIImage(named: "wave_placeholder"))
        bgImageView.frame = bounds
        bgImageView.contentMode = .ScaleAspectFill
        insertSubview(bgImageView, atIndex: 0)
        
        let effect     = UIBlurEffect(style: .Light)
        let blurView   = UIVisualEffectView(effect: effect)
        blurView.frame = bounds
        blurView.alpha = 0.96
        insertSubview(blurView, atIndex: 1)
    }
    
}
