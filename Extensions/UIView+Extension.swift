//
//  UIView+Extension.swift
//
//  Created by Augus on 9/4/15.
//  Copyright © 2015 iAugus. All rights reserved.
//

import UIKit

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.nextResponder()
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

extension UIView {
    func setFrameSize(size: CGSize) {
        var frame = self.frame
        frame.size = size
        self.frame = frame
    }
    
    func setFrameHeight(height: CGFloat) {
        var frame = self.frame
        frame.size.height = height
        self.frame = frame
    }
    
    func setFrameWidth(width: CGFloat) {
        var frame = self.frame
        frame.size.width = width
        self.frame = frame
    }

    func setFrameOriginX(originX: CGFloat) {
        var frame = self.frame
        frame.origin.x = originX
        self.frame = frame
    }
    
    func setFrameOriginY(originY: CGFloat) {
        var frame = self.frame
        frame.origin.y = originY
        self.frame = frame
    }

    /**
     set current view's absolute center to other view's center
     
     - parameter view: other view
     */
    func centerTo(view view: UIView) {
        self.frame.origin.x = view.bounds.midX - self.frame.width / 2
        self.frame.origin.y = view.bounds.midY - self.frame.height / 2
        
    }
}

extension UIView {
    
    func simulateHighlight() {
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.alpha = 0.5
            
            }, completion: { (_) -> Void in
                UIView.animateWithDuration(0.1, delay: 0.1, options: .CurveEaseInOut, animations: { () -> Void in
                    self.alpha = 1
                    }, completion: nil)
        })

    }
}
