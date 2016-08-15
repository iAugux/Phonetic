//
//  GradientView.swift
//  Phonetic
//
//  Created by Augus on 1/30/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit
import SnapKit

class GradientView: UIView {
    
    private var gradient: CAGradientLayer!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        backgroundColor = UIColor.clear
        addBlurEffect()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
//        configureGradientView(rect)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        gradient?.frame = frame
    }
    
    private func configureGradientView(_ frame: CGRect) {
        gradient        = CAGradientLayer()
        gradient.frame  = frame
        gradient.colors = [UIColor(red:0.0894, green:0.4823, blue:0.9112, alpha:0.1).cgColor,
            UIColor(red:0.6142, green:0.0611, blue:0.3474, alpha:0.1).cgColor]
        layer.insertSublayer(gradient, at: 1)
    }
    
    private func addBlurEffect() {
        
        let bgImageView = UIImageView(image: UIImage(named: "wave_placeholder"))
        bgImageView.contentMode = .scaleAspectFill
        insertSubview(bgImageView, at: 0)
        bgImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
        
        guard UIDevice.current.isBlurSupported() && !UIAccessibilityIsReduceTransparencyEnabled() else {
            let overlayView = UIView(frame: frame)
            overlayView.backgroundColor = UIColor(red: 0.498, green: 0.498, blue: 0.498, alpha: 0.926)
            insertSubview(overlayView, at: 1)
            return
        }
        
        let effect     = UIBlurEffect(style: .light)
        let blurView   = UIVisualEffectView(effect: effect)
        blurView.alpha = 0.97
        insertSubview(blurView, at: 1)
        blurView.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
    }
    
}
