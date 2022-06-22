//
//  GradientView.swift
//  Phonetic
//
//  Created by Augus on 1/30/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

final class GradientView: UIView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
        addBlurEffect()
    }

    private func addBlurEffect() {
        guard UIDevice.current.isBlurSupported && !UIAccessibility.isReduceTransparencyEnabled else {
            let overlayView = UIView(frame: frame)
            overlayView.backgroundColor = UIColor(red: 0.498, green: 0.498, blue: 0.498, alpha: 0.926)
            insertSubview(overlayView, at: 1)
            return
        }
        let effect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: effect)
        insertSubview(blurView, at: 0, pinningEdges: .all)
    }
}
