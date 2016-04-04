//
//  BlurImageView.swift
//  Phonetic
//
//  Created by Augus on 2/3/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

class BlurImageView: UIImageView {
    
    private var effectView: UIVisualEffectView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        if effectView == nil {
            configureViews()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        effectView?.frame = bounds
    }
    
    private func configureViews() {
        image = UIImage(named: "wave_placeholder")
        contentMode = .ScaleToFill
        
        if UIDevice.currentDevice().isBlurSupported() && !UIAccessibilityIsReduceTransparencyEnabled() {
            effectView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
            effectView.alpha = 0.98
        } else {
            effectView = UIVisualEffectView(effect: nil)
            effectView.backgroundColor = UIColor(red: 0.498, green: 0.498, blue: 0.498, alpha: 0.926)
        }
        
        effectView.frame = bounds
        insertSubview(effectView, atIndex: 0)
    }
    
}
