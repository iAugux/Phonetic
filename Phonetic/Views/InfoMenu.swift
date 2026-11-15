// Created by Augus on 9/28/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI

struct InfoMenu: View {
    var body: some View {
        Menu {
            Section {
                Link(destination: URL(string: "https://github.com/iAugux/Phonetic")!) {
                    Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }

            Section {
                Link(destination: URL(string: "https://trello.com/b/FFOaRrJ4")!) {
                    Label("Trello", systemImage: "rectangle.split.3x1")
                }
            }

            Section {
                Link(destination: APP.reviewURL(with: "1078961574")) {
                    Label("Rate Phonetic", systemImage: "star")
                }
            }

            if let version = APP.version, let build = APP.build {
                Section {
                    Text(verbatim: "v\(version) (\(build))")
                        .accessibilityLabel(Text("Version \(version) (Build \(build))"))
                }
            }
        } label: {
            Label("About", systemImage: Constants.infoSymbolName)
        }
        .accessibilityLabel("About")
    }
}
