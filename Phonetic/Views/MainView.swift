// Created by Augus on 9/28/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI

struct MainView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var executeButtonOffsetY: CGFloat = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    // Keep the content viewport separate from the bottom actions.
                    ZStack {
                        if appState.isProcessing {
                            GeometryReader { geometry in
                                ScrollView {
                                    VStack(spacing: 20) {
                                        Text(appState.statusText)
                                            .font(.subheadline.monospaced().weight(.medium))
                                            .foregroundStyle(.secondary)
                                            .frame(minHeight: 30)
                                            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : 280)
                                            .multilineTextAlignment(.center)
                                            .fixedSize(horizontal: false, vertical: true)

                                        CircularProgressView(percentage: appState.percentage)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 24)
                                    .padding(.top, dynamicTypeSize.isAccessibilitySize ? 16 : min(140, max(16, geometry.size.height * 0.18)))
                                    .padding(.bottom, 16)
                                }
                                .scrollIndicators(.hidden)
                                .scrollClipDisabled()
                            }
                            .transition(.opacity)
                        }
                    }
                    .animation(homeTransition, value: appState.isProcessing)
                    .zIndex(1)

                    GeometryReader { viewport in
                        ScrollView {
                            instructions(twoColumns: viewport.size.width >= 640 && !dynamicTypeSize.isAccessibilitySize)
                                .frame(maxWidth: .infinity, minHeight: viewport.size.height)
                        }
                        .scrollIndicators(.hidden)
                        .scrollClipDisabled()
                    }
                    .animation(homeTransition) { content in
                        content.opacity(appState.isProcessing ? 0 : 1)
                    }
                    .allowsHitTesting(!appState.isProcessing)
                    .accessibilityHidden(appState.isProcessing)
                    .zIndex(2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                homeActions
            }
            .background {
                // Full-screen decoration must not expand the content's safe-area layout.
                ZStack {
                    AppColor.canvasBackground
                    if !reduceMotion {
                        StarsOverlayRepresentable(isAnimating: appState.isProcessing)
                    }
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .animation(homeTransition) { content in
                            content.opacity(appState.isProcessing ? 0 : 1)
                        }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    InfoMenu()
                        .tint(Color.primary)
                        .disabled(appState.isProcessing)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        appState.showSettings = true
                    }) {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tint(Color.primary)
                    .popover(isPresented: $appState.showSettings) {
                        SettingView()
                            .frame(idealWidth: dynamicTypeSize.isAccessibilitySize ? 360 : 250, maxWidth: dynamicTypeSize.isAccessibilitySize ? 360 : 250)
                            .presentationCompactAdaptation(.popover)
                    }
                    .disabled(appState.isProcessing)
                }
            }
        }
        // Sheets
        .sheet(isPresented: $appState.showAdditionalSettings) {
            AdditionalSettingsView()
        }
        .sheet(isPresented: $appState.showWalkthrough) {
            WalkthroughView()
        }
        // Alerts
        .alert("Unable to Update Contacts", isPresented: $appState.showProcessingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appState.processingErrorMessage)
        }
        .alert("Stop Processing?", isPresented: $appState.showAbortAlert) {
            Button("Stop", role: .destructive) {
                appState.abort()
            }
            Button("Keep Processing", role: .cancel) {}
        } message: {
            Text("Stop the current task? Changes already made to your contacts will be kept.")
        }
        .alert("Clear Contact Fields?", isPresented: $appState.showCleanAlert) {
            Button("Clear", role: .destructive) {
                appState.performClean()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(appState.cleanAlertMessage)
        }
        .alert("Set Up Quick Search", isPresented: $appState.showChooseQuickSearchAlert) {
            Button("Open Settings") {
                appState.showAdditionalSettings = true
            }
            Button("Not Now") {}
            Button("Already Set Up", role: .cancel) {}
        } message: {
            Text("Choose a contact field for search initials. Nickname is recommended. You can change this in Settings.")
        }
    }

    private func instructions(twoColumns: Bool) -> some View {
        let layout = twoColumns
            ? AnyLayout(HStackLayout(alignment: .center, spacing: 32))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: 24))
        return layout {
            VStack(alignment: .leading, spacing: 12) {
                Text("Every name,\nin its place.")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
                Text("Add pinyin to Chinese names for alphabetical sorting and easier search.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 24) {
                contactExample

                if let outcome = appState.lastOutcome {
                    Label {
                        Text(verbatim: outcome.status)
                    } icon: {
                        switch outcome {
                        case .completed: Image(systemName: "checkmark.circle")
                        case .stopped: Image(systemName: "stop.circle")
                        case .failed: Image(systemName: "exclamationmark.circle")
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .accessibilityLabel(Text("Last Result"))
                    .accessibilityValue(Text(verbatim: outcome.status))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: twoColumns ? 760 : 360, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var contactExample: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pinyin Example")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(AppColor.accent)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: "林沐晴")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                    PinyinExampleText()
                        .font(.subheadline)
                        .foregroundStyle(AppColor.accent)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.04), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var homeActions: some View {
        VStack(spacing: 8) {
            executeButton
                .offset(y: executeButtonOffsetY)

            Button(role: .destructive, action: appState.clean) {
                Label("Clear Contact Fields", systemImage: "eraser")
                    .font(.subheadline.weight(.medium))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            // Reserve this space while processing so the primary action stays in the same place.
            .opacity(appState.isProcessing ? 0 : 1)
            .animation(homeTransition, value: appState.isProcessing)
            .disabled(appState.isProcessing)
            .accessibilityHidden(appState.isProcessing)
        }
        .frame(maxWidth: 360)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }

    private var executeButton: some View {
        Button(action: appState.execute) {
            HStack(spacing: 12) {
                if appState.canAbortProcessing {
                    Image(systemName: "stop.fill")
                        .accessibilityHidden(true)
                        .transition(.opacity)
                }
                executeButtonTitle
                    .contentTransition(.opacity)
            }
            .font(.headline)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 24)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: appState.canAbortProcessing)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: appState.isShowingCompletion)
        }
        .compatibleGlass()
        .tint(.primary)
        .controlSize(.large)
        .buttonBorderShape(.capsule)
        .disabled(appState.isShowingCompletion)
        .accessibilityActions {
            if !appState.isProcessing {
                Button("Clear Contact Fields") { appState.clean() }
            }
        }
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.5)
                .exclusively(before: TapGesture(count: 2).exclusively(before: TapGesture(count: 1)))
                .onEnded { value in
                    switch value {
                    case .first, .second(.first):
                        appState.clean()
                    case .second(.second):
                        appState.execute()
                    }
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.height < -30, appState.canAbortProcessing {
                        if !reduceMotion {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                executeButtonOffsetY = -25
                            }
                            withAnimation(.easeInOut(duration: 0.2).delay(0.2)) {
                                executeButtonOffsetY = 0
                            }
                        }
                        appState.showAbortAlert = true
                    }
                }
        )
    }

    private var executeButtonTitle: Text {
        if appState.isShowingCompletion {
            return Text(verbatim: appState.statusText)
        }
        if appState.canAbortProcessing {
            return Text("Stop Processing")
        }
        return Text("Add Pinyin")
    }

    private var homeTransition: Animation? {
        reduceMotion ? nil : .easeInOut(duration: appState.isProcessing ? 0.4 : 0.65)
    }
}
