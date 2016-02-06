//
//  UIViewController+Extension.swift
//
//  Created by Augus on 9/30/15.
//  Copyright © 2015 iAugus. All rights reserved.
//

import UIKit

// MARK: - top bar (status bar + navigation bar)
extension UIViewController {
    
    func statusBarFrame() -> CGRect {
        return view.window?.convertRect(UIApplication.sharedApplication().statusBarFrame, toView: view) ?? CGRectZero
    }
    
    func topBarHeight() -> CGFloat {
        var navBarHeight: CGFloat {
            guard let bar = navigationController?.navigationBar else { return 0 }
            return view.window?.convertRect(bar.frame, toView: view).height ?? 0
        }
        let statusBarHeight = view.window?.convertRect(UIApplication.sharedApplication().statusBarFrame, toView: view).height ?? 0
        return statusBarHeight + navBarHeight
    }
    
    /**
     While trying to present a new controller, current controller' bar may disappear temporary.
     But I still need the real height of top bar.
     - Why not set a constant (64.0 or 32.0)? Apple may change the constant in some device in the future.
    */
    func topBarHeightWhenTemporaryDisappear() -> CGFloat {
        let key = "kAUSTopBarHeightWhenTemporaryDisappear"
        if NSUserDefaults.standardUserDefaults().valueForKey(key) == nil {
            NSUserDefaults.standardUserDefaults().setValue(topBarHeight(), forKey: key)
        }
        else if topBarHeight() != 0 && topBarHeight() != NSUserDefaults.standardUserDefaults().valueForKey(key) as! CGFloat {
            NSUserDefaults.standardUserDefaults().setValue(topBarHeight(), forKey: key)
        }
        return NSUserDefaults.standardUserDefaults().valueForKey(key) as! CGFloat
    }
    
}

// MARK: - keyboard notification
extension UIViewController {
    func keyboardWillChangeFrameNotification(notification: NSNotification, scrollBottomConstant: NSLayoutConstraint) {
        let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
        let curve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
        let keyboardBeginFrame = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
        let keyboardEndFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        let screenHeight = UIScreen.mainScreen().bounds.height
        let isBeginOrEnd = keyboardBeginFrame.origin.y == screenHeight || keyboardEndFrame.origin.y == screenHeight
        let heightOffset = keyboardBeginFrame.origin.y - keyboardEndFrame.origin.y - (isBeginOrEnd ? bottomLayoutGuide.length : 0)
        
        UIView.animateWithDuration(duration.doubleValue,
            delay: 0,
            options: UIViewAnimationOptions(rawValue: UInt(curve.integerValue << 16)),
            animations: { () in
                scrollBottomConstant.constant = scrollBottomConstant.constant + heightOffset
                self.view.layoutIfNeeded()
            },
            completion: nil
        )
    }
    
}

// MARK: - dismiss view controller
extension UIViewController {

    func dismissViewController() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func dismissViewControllerWithoutAnimation() {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
}