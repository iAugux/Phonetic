//
//  AppIconImageView.swift
//  Phonetic
//
//  Created by Augus on 1/30/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

class AppIconImageView: UIImageView {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        image              = UIImage(named: "iTranslator")
        clipsToBounds      = true
        layer.cornerRadius = frame.width * 0.25
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(iconDidTap))
        addGestureRecognizer(recognizer)
    }
    
    func iconDidTap() {
        parentViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            let appURL = NSURL(string: "https://itunes.apple.com/app/id1063627763")
            if UIApplication.sharedApplication().canOpenURL(appURL!) {
                UIApplication.sharedApplication().openURL(appURL!)
            }            
        })
    }

}
