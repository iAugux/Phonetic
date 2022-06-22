// Created by Augus on 2021/10/1
// Copyright © 2021 Augus <iAugux@gmail.com>

import UIKit

extension UIDevice {
    // REFERENCE: - http://stackoverflow.com/a/29997626/4656574
    /// Check if device supports blur
    var isBlurSupported: Bool {
        let notSupported = ["iPad", "iPad1,1", "iPhone1,1", "iPhone1,2", "iPhone2,1", "iPhone3,1", "iPhone3,2", "iPhone3,3", "iPod1,1", "iPod2,1", "iPod2,2", "iPod3,1", "iPod4,1", "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4", "iPad3,1", "iPad3,2", "iPad3,3"]
        return !notSupported.contains(hardwareString)
    }

    private var hardwareString: String {
        var name: [Int32] = [CTL_HW, HW_MACHINE]
        var size = 2
        sysctl(&name, 2, nil, &size, nil, 0)
        var hw_machine = [CChar](repeating: 0, count: Int(size))
        sysctl(&name, 2, &hw_machine, &size, nil, 0)
        let hardware = String(cString: hw_machine)
        return hardware
    }
}
