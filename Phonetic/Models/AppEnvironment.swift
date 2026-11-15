// Created by Augus on 7/30/23
// Copyright © 2023 Augus <iAugux@gmail.com>

import Foundation

enum AppEnvironment: String {
    case development, production
    static var current: AppEnvironment {
#if DEBUG
        return .development
#else
        // Callers only use this distinction to guard development-only contact generation.
        // Both TestFlight and App Store builds must keep those generators disabled.
        return .production
#endif
    }
}
