//
//  BlurBackgroundView.swift
//  BlurActionSheetDemo
//
//  Created by Augus on 2/11/16.
//  Copyright © 2016 nathan. All rights reserved.
//

import UIKit

class BlurBackgroundView: UIView {
    var effect: UIBlurEffect! {
        didSet {
            blurView.effect = effect
        }
    }

    private lazy var blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 0.7, alpha: 0)
        addSubview(blurView, pinningEdges: .all)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
