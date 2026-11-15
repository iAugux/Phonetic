// Created by Augus on 10/25/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI

struct CompatibleGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glass)
        } else {
            content.buttonStyle(.bordered)
        }
    }
}

struct CompatibleGlassProminentModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}

extension View {
    func compatibleGlass() -> some View {
        modifier(CompatibleGlassModifier())
    }

    func compatibleGlassProminent() -> some View {
        modifier(CompatibleGlassProminentModifier())
    }
}
