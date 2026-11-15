// Created by Augus on 10/1/21
// Copyright © 2021 Augus <iAugux@gmail.com>

import UIKit

extension UIDevice {
    var isSimulator: Bool {
#if targetEnvironment(simulator)
        return true
#else
        return false
#endif
    }
}
