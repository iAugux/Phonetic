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
        
        image = UIImage(named: "wave_placeholder")
        contentMode = .ScaleAspectFill
        
        effectView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        effectView.frame = frame
        effectView.alpha = 0.98
        addSubview(effectView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        effectView.frame = bounds
    }
    
    
}
