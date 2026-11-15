// Created by Augus on 10/27/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI

enum AppColor {
    static let accent = Color("AccentColor")
    static let onAccent = Color.black

    // Opaque surfaces approximate the previous dark-gray compositions without depending on
    // each view's background or repeating brightness/opacity adjustments throughout the app.
    static let pageBackground = rgb(0x222223)
    static let inputBackground = rgb(0x2C2C2D)
    static let canvasBackground = Color.black

    // These accents belong to the onboarding illustrations, rather than general UI controls.
    static let onboardingNotificationAccent = Color(red: 0.961, green: 0.651, blue: 0.137)
    static let onboardingQuickSearchAccent = Color(red: 0.494, green: 0.827, blue: 0.129)
    static let onboardingDisplayNamesAccent = Color(red: 0.592, green: 0.396, blue: 0.796)

    private static func rgb(_ hex: UInt) -> Color {
        Color(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
