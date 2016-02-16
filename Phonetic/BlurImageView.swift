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
        
        effectView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        effectView.frame = bounds
        effectView.alpha = 0.98
        insertSubview(effectView, atIndex: 0)
    }
    
}
