//
//  BlurBackgroundView.swift
//  BlurActionSheetDemo
//
//  Created by Augus on 2/11/16.
//  Copyright © 2016 nathan. All rights reserved.
//

import UIKit
import SnapKit

class BlurBackgroundView: UIView {
    
    var effect: UIBlurEffect! {
        didSet {
            blurView?.effect = effect
        }
    }
    
    private var blurView: UIVisualEffectView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor(white: 0.7, alpha: 0)
        
        blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        addSubview(blurView)
        blurView.snp.makeConstraints { (make) in
            make.edges.equalTo(UIEdgeInsetsZero)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
