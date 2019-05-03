//
//  AppIconImageView.swift
//  Phonetic
//
//  Created by Augus on 1/30/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

final class AppIconImageView: UIImageView {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        image = UIImage(named: "iTranslator")
        clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.width * 0.23
    }
    
    func iconDidTap() {
        parentViewController?.dismiss(animated: true, completion: {
            let appURL = URL(string: "https://itunes.apple.com/app/id1063627763")!
            if UIApplication.shared.canOpenURL(appURL) { UIApplication.shared.openURL(appURL) }
        })
    }
}
