//
//  UIImage+Utilities.swift
//  Phonetic
//
//  Created by Augus on 2020/4/17.
//  Copyright © 2020 iAugus. All rights reserved.
//

import UIKit

extension UIImage {
    static let close: UIImage = {
        if #available(iOS 13.0, *) {
            return (UIImage(systemName: "xmark") ?? #imageLiteral(resourceName: "close")).templateRender
        } else {
            return #imageLiteral(resourceName: "close").templateRender
        }
    }()
}
