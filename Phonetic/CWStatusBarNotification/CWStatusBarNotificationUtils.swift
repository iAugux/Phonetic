//
//  CWStatusBarNotificationUtils.swift
//  CWNotificationDemo
//
//  Created by Cezary Wojcik on 7/11/15.
//  Copyright © 2015 Cezary Wojcik. All rights reserved.
//

import UIKit

// MARK: - helper functions

func systemVersionLessThan(_ value: String) -> Bool {
    return UIDevice.current.systemVersion.compare(value, options: .numeric) == .orderedAscending
}

// MARK: - ScrollLabel

open class ScrollLabel: UILabel {
    // MARK: - properties
    private let padding: CGFloat = 10.0
    private let scrollSpeed: CGFloat = 40.0
    private let scrollDelay: CGFloat = 1.0
    private var textImage: UIImageView?

    // MARK: - setup
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.textImage = UIImageView()
        self.addSubview(self.textImage!)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override open func drawText(in rect: CGRect) {
        guard self.scrollOffset() > 0 else {
            self.textImage = nil
            super.drawText(in: rect.insetBy(dx: padding, dy: 0))
            return
        }
        guard let textImage = self.textImage else {
            return
        }
        var frame = rect // because rect is immutable
        frame.size.width = self.fullWidth() + padding * 2
        UIGraphicsBeginImageContextWithOptions(frame.size, false,
                                               UIScreen.main.scale)
        super.drawText(in: frame)
        textImage.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        textImage.sizeToFit()
        UIView.animate(withDuration: TimeInterval(self.scrollTime()
            - scrollDelay),
                       delay: TimeInterval(scrollDelay),
                       options: UIView.AnimationOptions(arrayLiteral:
                        UIView.AnimationOptions.beginFromCurrentState,
                                                        UIView.AnimationOptions()),
                       animations: { () -> () in
                        textImage.transform = CGAffineTransform(translationX: -1
                            * self.scrollOffset(), y: 0)
        }, completion: nil)
    }

    // MARK - methods
    private func fullWidth() -> CGFloat {
        guard let content = self.text else { return 0.0 }
        let size = NSString(string: content).size(withAttributes: [NSAttributedString.Key.font: self.font!])
        return size.width
    }

    private func scrollOffset() -> CGFloat {
        guard self.numberOfLines == 1 else {
            return 0.0
        }
        let insetRect = self.bounds.insetBy(dx: padding, dy: 0.0)
        return max(0, self.fullWidth() - insetRect.size.width)
    }

    func scrollTime() -> CGFloat {
        return self.scrollOffset() > 0 ? self.scrollOffset() / scrollSpeed
            + scrollDelay: 0
    }
}

// MARK: - CWWindowContainer

open class CWWindowContainer: UIWindow {
    var notificationHeight: CGFloat = 0.0

    override open func hitTest(_ pt: CGPoint, with event: UIEvent?) -> UIView? {
        var height: CGFloat = 0.0
        if systemVersionLessThan("8.0.0") && UIApplication.shared.statusBarOrientation.isLandscape {
            height = UIApplication.shared.statusBarFrame.size.width
        } else {
            height = UIApplication.shared.statusBarFrame.size.height
        }
        if pt.y > 0 && pt.y < (self.notificationHeight != 0.0 ?
            self.notificationHeight: height) {
            return super.hitTest(pt, with: event)
        }
        return nil
    }
}

// MARK: - CWViewController
class CWViewController: UIViewController {
    var localPreferredStatusBarStyle: UIStatusBarStyle = .default
    var localSupportedInterfaceOrientations: UIInterfaceOrientationMask = []

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.localPreferredStatusBarStyle
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.localSupportedInterfaceOrientations
    }

    override var prefersStatusBarHidden: Bool {
        let statusBarHeight = UIApplication.shared.statusBarFrame
            .size.height
        return !(statusBarHeight > 0)
    }
}

// MARK: - delayed closure handle

typealias CWDelayedClosureHandle = (Bool) -> ()

func performClosureAfterDelay(_ seconds: Double, closure: Closure?) -> CWDelayedClosureHandle? {
    guard closure != nil else { return nil }
    var closureToExecute: Closure! = closure // copy?
    var delayHandleCopy: CWDelayedClosureHandle? = nil
    let delayHandle: CWDelayedClosureHandle = {
        (cancel: Bool) -> () in
        if !cancel && closureToExecute != nil {
            DispatchQueue.main.async(execute: closureToExecute)
        }
        closureToExecute = nil
        delayHandleCopy = nil
    }
    delayHandleCopy = delayHandle
    let delay = Int64(Double(seconds) * Double(NSEC_PER_SEC))
    let after = DispatchTime.now() + Double(delay) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: after, execute: {
        delayHandleCopy?(false)
    })
    return delayHandleCopy
}

func cancelDelayedClosure(_ delayedHandle: CWDelayedClosureHandle?) {
    delayedHandle?(true)
}
