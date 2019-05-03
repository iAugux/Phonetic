//
//  BlurImageView.swift
//  Phonetic
//
//  Created by Augus on 2/3/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

final class BlurImageView: UIImageView {
    private lazy var effectView = UIVisualEffectView(effect: nil)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        effectView.frame = bounds
    }
    
    private func configureViews() {
        image = UIImage(named: "wave_placeholder")
        contentMode = .scaleToFill
        if UIDevice.current.isBlurSupported && !UIAccessibility.isReduceTransparencyEnabled {
            effectView.effect = UIBlurEffect(style: .light)
        } else {
            effectView.effect = nil
            effectView.backgroundColor = UIColor(red: 0.498, green: 0.498, blue: 0.498, alpha: 0.926)
        }
        insertSubview(effectView, at: 0, pinningEdges: .all)
    }
}
