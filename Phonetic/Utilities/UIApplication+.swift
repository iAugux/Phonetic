// Created by Augus on 10/2/21
// Copyright © 2021 Augus <iAugux@gmail.com>

import UIKit

extension UIApplication {
    var topMostViewController: UIViewController? {
        let keyWindow = connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first { $0.isKeyWindow }
        var topController = keyWindow?.rootViewController
        while let presented = topController?.presentedViewController {
            topController = presented
        }
        return topController
    }

    func open(_ url: URL?) {
        guard let url else { return }
        open(url, options: [:], completionHandler: nil)
    }
}
