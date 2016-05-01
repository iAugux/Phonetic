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

extension UIView {
    
    func isPointInside(fromView: UIView, point: CGPoint, event: UIEvent?) -> Bool {
        return pointInside(fromView.convertPoint(point, toView: self), withEvent: event)
    }
}


// MARK: - rotation animation

extension UIView {
    
    /**
     Angle: 𝞹
     
     - parameter duration:           <#duration description#>
     - parameter beginWithClockwise: <#beginWithClockwise description#>
     - parameter clockwise:          <#clockwise description#>
     - parameter animated:           <#animated description#>
     */
    func rotationAnimation(duration: CFTimeInterval? = 0.4, beginWithClockwise: Bool, clockwise: Bool, animated: Bool) {
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        
        let angle: Double = beginWithClockwise ? (clockwise ? M_PI : 0) : (clockwise ? 0 : -M_PI)
        
        if beginWithClockwise {
            if !clockwise { rotationAnimation.fromValue = M_PI }
        } else {
            if clockwise { rotationAnimation.fromValue = -M_PI }
        }
        
        
        rotationAnimation.toValue = angle
        rotationAnimation.duration = animated ? duration! : 0
        rotationAnimation.repeatCount = 0
        rotationAnimation.delegate = self
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        rotationAnimation.fillMode = kCAFillModeForwards
        rotationAnimation.removedOnCompletion = false
        
        layer.addAnimation(rotationAnimation, forKey: "rotationAnimation")
    }
    
    /**
     Angle: 𝞹/2
     
     - parameter duration:  <#duration description#>
     - parameter clockwise: <#clockwise description#>
     - parameter animated:  <#animated description#>
     */
    func rotationAnimation(duration: NSTimeInterval, clockwise: Bool, animated: Bool) {
        
        let angle = CGFloat(clockwise ? M_PI_2 : -M_PI_2)
        
        if animated {
            UIView.animateWithDuration(duration, delay: 0, options: .CurveLinear, animations: { () -> Void in
                self.transform = CGAffineTransformRotate(self.transform, angle)
                }, completion: nil)
        } else {
            self.transform = CGAffineTransformRotate(self.transform, angle)
        }
        
    }

}


// MARK: - Twinkle

extension UIView {
    
    func twinkling(duration: NSTimeInterval, minAlpha: CGFloat = 0, maxAlpha: CGFloat = 1) {
        
        UIView.animateWithDuration(duration, animations: {
            self.alpha = minAlpha
            
        }) { (finished) in
            
            if finished {
                UIView.animateWithDuration(duration, animations: {
                    self.alpha = maxAlpha
                    }, completion: { (finished) in
                        
                        if finished {
                            self.twinkling(duration, minAlpha: minAlpha, maxAlpha: maxAlpha)
                        }
                })
            }
        }
    }
}
