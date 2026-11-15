// Created by Augus on 9/5/25
// Copyright © 2025 Augus <iAugux@gmail.com>

enum Constants {
    static var infoSymbolName: String {
        // Modern toolbars already provide the circular Liquid Glass background.
        if #available(iOS 26.0, *) {
            return "info"
        }
        return "info.circle"
    }
}
