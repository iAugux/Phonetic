//
//  Toast.swift
//
//  Created by Augus on 4/23/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation


class Toast {
    
    fileprivate static var notification: CWStatusBarNotification = {
        let notification = CWStatusBarNotification()
        notification.notificationAnimationInStyle = .top
        notification.notificationAnimationOutStyle = .top
        return notification
    }()
    
    static func make(_ message: String, delay: TimeInterval = 0, interval: TimeInterval = 1.0) {
        
        let make = {
            notification.displayNotificationWithMessage(message, forDuration: interval)
        }
        
        if delay == 0 {
            make()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                make()
            })
        }
    }
    
}
