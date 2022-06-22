// Created by Augus on 2021/10/2
// Copyright © 2021 Augus <iAugux@gmail.com>

import UIKit

extension UIApplication {
    func open(_ url: URL?) {
        guard let url = url else { return }
        if #available(iOS 10.0, *) {
            self.open(url, options: [:], completionHandler: nil)
        } else {
            self.openURL(url)
        }
    }
}
