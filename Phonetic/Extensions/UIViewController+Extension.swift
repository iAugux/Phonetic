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
        return view.window?.convert(UIApplication.shared.statusBarFrame, to: view) ?? CGRect.zero
    }
    
    func topBarHeight() -> CGFloat {
        var navBarHeight: CGFloat {
            guard let bar = navigationController?.navigationBar else { return 0 }
            return view.window?.convert(bar.frame, to: view).height ?? 0
        }
        let statusBarHeight = view.window?.convert(UIApplication.shared.statusBarFrame, to: view).height ?? 0
        return statusBarHeight + navBarHeight
    }
    
    /**
     While trying to present a new controller, current controller' bar may disappear temporary.
     But I still need the real height of top bar.
     - Why not set a constant (64.0 or 32.0)? Apple may change the constant in some device in the future.
    */
    func topBarHeightWhenTemporaryDisappear() -> CGFloat {
        let key = "kAUSTopBarHeightWhenTemporaryDisappear"
        if UserDefaults.standard.value(forKey: key) == nil {
            UserDefaults.standard.setValue(topBarHeight(), forKey: key)
        }
        else if topBarHeight() != 0 && topBarHeight() != UserDefaults.standard.value(forKey: key) as! CGFloat {
            UserDefaults.standard.setValue(topBarHeight(), forKey: key)
        }
        return UserDefaults.standard.value(forKey: key) as! CGFloat
    }
    
}

// MARK: - keyboard notification
extension UIViewController {
    func keyboardWillChangeFrameNotification(_ notification: Notification, scrollBottomConstant: NSLayoutConstraint) {
        let duration = (notification as NSNotification).userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
        let curve = (notification as NSNotification).userInfo?[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
        let keyboardBeginFrame = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let keyboardEndFrame = ((notification as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let screenHeight = UIScreen.main.bounds.height
        let isBeginOrEnd = keyboardBeginFrame.origin.y == screenHeight || keyboardEndFrame.origin.y == screenHeight
        let heightOffset = keyboardBeginFrame.origin.y - keyboardEndFrame.origin.y - (isBeginOrEnd ? bottomLayoutGuide.length : 0)
        
        UIView.animate(withDuration: duration.doubleValue,
            delay: 0,
            options: UIViewAnimationOptions(rawValue: UInt(curve.intValue << 16)),
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
        self.dismiss(animated: true, completion: nil)
    }
    
    func dismissViewControllerWithoutAnimation() {
        self.dismiss(animated: false, completion: nil)
    }
    
}
