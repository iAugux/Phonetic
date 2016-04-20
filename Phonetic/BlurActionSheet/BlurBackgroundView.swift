//
//  BlurBackgroundView.swift
//  BlurActionSheetDemo
//
//  Created by Augus on 2/11/16.
//  Copyright © 2016 nathan. All rights reserved.
//

import UIKit

class BlurBackgroundView: UIView {

    private var blurView: UIVisualEffectView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor(white: 0.7, alpha: 0)
        
        blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        addSubview(blurView)
        blurView.snp_makeConstraints { (make) in
            make.edges.equalTo(UIEdgeInsetsZero)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
