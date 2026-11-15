// Created by Augus on 9/28/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI

struct SettingView: View {
    @AppStorage(kFixPolyphonicChar) private var fixPolyphonicChar: Bool = kFixPolyphonicCharDefaultBool
    @AppStorage(kUseTones) private var useTones: Bool = kUseTonesDefaultBool
    @AppStorage(kUpcasePinyin) private var upcasePinyin: Bool = kUpcasePinyinDefaultBool

    @State private var showPolyphonic = false
    @State private var showAdditionalSettings = false

    var body: some View {
        ViewThatFits(in: .vertical) {
            settingsContent
            ScrollView { settingsContent }
        }
        .sheet(isPresented: $showPolyphonic) {
            PolyphonicView()
        }
        .sheet(isPresented: $showAdditionalSettings) {
            AdditionalSettingsView()
        }
    }

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 0) {
                    Text("Fix Polyphone")
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityHidden(true)

                    Button(action: { showPolyphonic = true }) {
                        Image(systemName: "plus.circle")
                            .font(.body)
                            .foregroundStyle(AppColor.accent)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Polyphonic Characters")

                    Spacer(minLength: 8)

                    Toggle("Fix Polyphone", isOn: $fixPolyphonicChar)
                        .labelsHidden()
                }
                .font(.footnote)
                .tint(AppColor.accent)

                Toggle("Use Tones", isOn: $useTones)
                    .font(.footnote)
                    .frame(minHeight: 44)
                    .tint(AppColor.accent)

                Toggle("Upcase Pinyin", isOn: $upcasePinyin)
                    .font(.footnote)
                    .frame(minHeight: 44)
                    .tint(AppColor.accent)
            }

            Divider()
                .padding(.vertical, 4)

            // Explanatory Notes
            VStack(alignment: .leading, spacing: 10) {
                explanatoryNote("Fix Polyphone", example: "秘(bì)、单(shàn)、解(xiè) ...")
                explanatoryNote("Use Tones", example: "美 [ mei ] ➟ [ měi ]")
                explanatoryNote("Upcase Pinyin", example: "[ Lin Muqing ] ➟ [ Lin MuQing ]")
            }

            // More Settings Button
            Button(action: { showAdditionalSettings = true }) {
                Text("Additional Settings")
                    .font(.callout.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .compatibleGlass()
            .controlSize(.regular)
            .tint(.primary)
            .padding(.top, 6)
        }
        .padding(20)
    }

    private func explanatoryNote(_ title: LocalizedStringKey, example: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(verbatim: "✪")
                .font(.caption2.weight(.semibold))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption2.weight(.semibold))

                Text(example)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
