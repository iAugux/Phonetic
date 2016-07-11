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
            parentResponder = parentResponder!.next()
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

extension UIView {
    func setFrameSize(_ size: CGSize) {
        var frame = self.frame
        frame.size = size
        self.frame = frame
    }
    
    func setFrameHeight(_ height: CGFloat) {
        var frame = self.frame
        frame.size.height = height
        self.frame = frame
    }
    
    func setFrameWidth(_ width: CGFloat) {
        var frame = self.frame
        frame.size.width = width
        self.frame = frame
    }

    func setFrameOriginX(_ originX: CGFloat) {
        var frame = self.frame
        frame.origin.x = originX
        self.frame = frame
    }
    
    func setFrameOriginY(_ originY: CGFloat) {
        var frame = self.frame
        frame.origin.y = originY
        self.frame = frame
    }

    /**
     set current view's absolute center to other view's center
     
     - parameter view: other view
     */
    func centerTo(view: UIView) {
        self.frame.origin.x = view.bounds.midX - self.frame.width / 2
        self.frame.origin.y = view.bounds.midY - self.frame.height / 2
        
    }
}

extension UIView {
    
    func simulateHighlight() {
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.alpha = 0.5
            
            }, completion: { (_) -> Void in
                UIView.animate(withDuration: 0.1, delay: 0.1, options: UIViewAnimationOptions(), animations: { () -> Void in
                    self.alpha = 1
                    }, completion: nil)
        })

    }
}

extension UIView {
    
    func isPointInside(_ fromView: UIView, point: CGPoint, event: UIEvent?) -> Bool {
        return self.point(inside: fromView.convert(point, to: self), with: event)
    }
}


// MARK: - rotation animation

extension UIView: CAAnimationDelegate {
    
    /**
     Angle: 𝞹
     
     - parameter duration:           <#duration description#>
     - parameter beginWithClockwise: <#beginWithClockwise description#>
     - parameter clockwise:          <#clockwise description#>
     - parameter animated:           <#animated description#>
     */
    func rotationAnimation(_ duration: CFTimeInterval? = 0.4, beginWithClockwise: Bool, clockwise: Bool, animated: Bool) {
        
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
        rotationAnimation.isRemovedOnCompletion = false
        
        layer.add(rotationAnimation, forKey: "rotationAnimation")
    }
    
    /**
     Angle: 𝞹/2
     
     - parameter duration:  <#duration description#>
     - parameter clockwise: <#clockwise description#>
     - parameter animated:  <#animated description#>
     */
    func rotationAnimation(_ duration: TimeInterval, clockwise: Bool, animated: Bool) {
        
        let angle = CGFloat(clockwise ? M_PI_2 : -M_PI_2)
        
        if animated {
            UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: { () -> Void in
                self.transform = self.transform.rotate(angle)
                }, completion: nil)
        } else {
            self.transform = self.transform.rotate(angle)
        }
        
    }

}


// MARK: - Twinkle

extension UIView {
    
    func twinkling(_ duration: TimeInterval, minAlpha: CGFloat = 0, maxAlpha: CGFloat = 1) {
        
        UIView.animate(withDuration: duration, animations: {
            self.alpha = minAlpha
            
        }) { (finished) in
            
            if finished {
                UIView.animate(withDuration: duration, animations: {
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
