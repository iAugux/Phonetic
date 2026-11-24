// Created by Augus on 9/28/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI

struct PolyphonicView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("kEnableAllPolyphonicCharacters") private var enableAll: Bool = true

    private let sections: [(title: String, chars: [Polyphonic])] = [
        ("B", [PolyphonicChar.b1, PolyphonicChar.b2, PolyphonicChar.b3]),
        ("C", [PolyphonicChar.c1, PolyphonicChar.c2, PolyphonicChar.c3]),
        ("D", [PolyphonicChar.d1]),
        ("G", [PolyphonicChar.g1, PolyphonicChar.g2, PolyphonicChar.g3, PolyphonicChar.g4]),
        ("H", [PolyphonicChar.h1]),
        ("J", [PolyphonicChar.j1, PolyphonicChar.j2]),
        ("K", [PolyphonicChar.k1]),
        ("M", [PolyphonicChar.m1, PolyphonicChar.m2]),
        ("N", [PolyphonicChar.n1]),
        ("O", [PolyphonicChar.o1]),
        ("P", [PolyphonicChar.p1, PolyphonicChar.p2]),
        ("Q", [PolyphonicChar.q2, PolyphonicChar.q3, PolyphonicChar.q4, PolyphonicChar.q5]),
        ("R", [PolyphonicChar.r1]),
        ("S", [PolyphonicChar.s1, PolyphonicChar.s2, PolyphonicChar.s3, PolyphonicChar.s4]),
        ("X", [PolyphonicChar.x1, PolyphonicChar.x2]),
        ("Y", [PolyphonicChar.y1, PolyphonicChar.y2, PolyphonicChar.y3, PolyphonicChar.y4]),
        ("Z", [PolyphonicChar.z1, PolyphonicChar.z2, PolyphonicChar.z3, PolyphonicChar.z4, PolyphonicChar.z5]),
    ]

    var body: some View {
        NavigationStack {
            List {
                // Master switch header
                Section {
                    Toggle(isOn: Binding(
                        get: { enableAll },
                        set: { newValue in
                            enableAll = newValue
                            toggleAll(newValue)
                        }
                    )) {
                        Text("Enable All")
                            .font(.callout.weight(.medium))
                    }
                    .tint(AppColor.accent)
                } footer: {
                    Text("Only corrects polyphonic characters in family names, not given names.")
                }

                // Alphabetical sections
                ForEach(sections, id: \.title) { section in
                    Section {
                        ForEach(section.chars, id: \.key) { char in
                            PolyphonicRowView(char: char)
                        }
                    } header: {
                        Text(section.title).foregroundStyle(.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.pageBackground)
            .navigationTitle("Polyphonic Characters")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Label("Close", systemImage: "xmark")
                    }
                    .tint(Color.primary)
                }
            }
        }
    }

    private func toggleAll(_ isOn: Bool) {
        for polyphonic in PolyphonicChar.all {
            UserDefaults.standard.set(isOn, forKey: polyphonic.key)
        }
    }
}

private struct PolyphonicRowView: View {
    let char: Polyphonic

    @AppStorage private var isOn: Bool

    init(char: Polyphonic) {
        self.char = char
        _isOn = AppStorage(wrappedValue: true, char.key)
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(alignment: .firstTextBaseline) {
                Text(char.character)
                    .font(.callout)

                Text(verbatim: "『 \(char.pinyin) 』")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(AppColor.accent)
    }
}
