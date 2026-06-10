// Created by Augus on 2021/10/2
// Copyright © 2021 Augus <iAugux@gmail.com>

import UIKit
import UserNotifications

extension UIApplication {
    func open(_ url: URL?) {
        guard let url = url else { return }
        self.open(url, options: [:], completionHandler: nil)
    }

    func requestUserNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { _, _ in })
    }

    func updateApplicationIconBadgeNumber(to badgeNumber: Int) {
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(badgeNumber)
        } else {
            applicationIconBadgeNumber = badgeNumber
        }
    }

    func scheduleLocalNotification(alertBody: String) {
        let content = UNMutableNotificationContent()
        content.body = alertBody
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
