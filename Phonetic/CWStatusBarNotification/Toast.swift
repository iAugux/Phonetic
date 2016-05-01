//
//  Toast.swift
//
//  Created by Augus on 4/23/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation


class Toast {
    
    private static var notification: CWStatusBarNotification = {
        let notification = CWStatusBarNotification()
        notification.notificationAnimationInStyle = .Top
        notification.notificationAnimationOutStyle = .Top
        return notification
    }()
    
    static func make(message: String, delay: NSTimeInterval = 0, interval: NSTimeInterval = 1.0) {
        
        let make = {
            notification.displayNotificationWithMessage(message, forDuration: interval)
        }
        
        dispatch_async(dispatch_get_main_queue()) { 
            
            if delay != 0 {
                let delayInSeconds: Double = delay
                let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * delayInSeconds))
                dispatch_after(popTime, dispatch_get_main_queue(), {
                    make()
                })
            } else {
                make()
            }
        }
        
    }
    
}