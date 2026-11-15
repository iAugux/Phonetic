// Created by Augus on 9/28/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI
import UIKit

struct StarsOverlayRepresentable: UIViewRepresentable {
    var isAnimating: Bool

    func makeUIView(context: Context) -> StarsOverlay {
        let view = StarsOverlay(frame: .zero)
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: StarsOverlay, context: Context) {
        if isAnimating {
            uiView.startAnimating()
        } else {
            uiView.stopAnimating()
        }
    }

    static func dismantleUIView(_ uiView: StarsOverlay, coordinator: ()) {
        uiView.stopAnimating()
    }
}
