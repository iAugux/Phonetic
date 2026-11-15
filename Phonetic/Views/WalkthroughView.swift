// Created by Augus on 9/28/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import Contacts
import SwiftUI
import UIKit
import UserNotifications

struct WalkthroughView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var currentPage: WalkthroughStep = .contacts
    @State private var contactsAuthorization = CNContactStore.authorizationStatus(for: .contacts)
    @State private var notificationAuthorization: UNAuthorizationStatus = .notDetermined
    @State private var isRequestingPermission = false

    @AppStorage(kEnableNickname) private var enableNickname = kEnableNicknameDefaultBool
    @AppStorage(kEnableCustomName) private var enableCustomName = kEnableCustomNameDefaultBool
    @AppStorage(kQuickSearchKeyRawValue) private var quickSearchKeyRawValue = 0

    private let quickSearchOptions = (0..<QuickSearch.cancel.rawValue).compactMap(QuickSearch.init(rawValue:))

    var body: some View {
        GeometryReader { geometry in
            let landscape = geometry.size.width > geometry.size.height
            let contentMaxWidth: CGFloat = landscape ? 1040 : 560
            ZStack {
                AppColor.pageBackground
                    .ignoresSafeArea()

                RadialGradient(colors: [currentPage.accent.opacity(0.15), .clear], center: .topLeading, startRadius: 0, endRadius: 550)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header(compact: landscape)
                        .frame(maxWidth: contentMaxWidth)

                    pager(landscape: landscape, contentMaxWidth: contentMaxWidth, contentInsets: geometry.safeAreaInsets)

                    footer(compact: landscape)
                        .frame(maxWidth: contentMaxWidth)
                        // Scroll gestures update selection without the button actions' animation transaction.
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: currentPage)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await refreshPermissions()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await refreshPermissions() }
            }
        }
    }

    private func pager(landscape: Bool, contentMaxWidth: CGFloat, contentInsets: EdgeInsets) -> some View {
        GeometryReader { viewport in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(WalkthroughStep.allCases, id: \.self) { step in
                        page(step, landscape: landscape)
                            .frame(maxWidth: contentMaxWidth)
                            .frame(maxWidth: .infinity)
                            // Preserve the outer safe area; the expanded viewport can report zero side insets.
                            .padding(.leading, contentInsets.leading)
                            .padding(.trailing, contentInsets.trailing)
                            // Match the paging stride to the viewport, including at the first and last page.
                            .frame(width: viewport.size.width, height: viewport.size.height)
                            .id(step)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: Binding($currentPage), anchor: .leading)
            .ignoresSafeArea(.container, edges: .horizontal)
        }
        .ignoresSafeArea(.container, edges: .horizontal)
        .disabled(isRequestingPermission)
        .allowsHitTesting(!isRequestingPermission)
    }

    private func header(compact: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "character.book.closed.fill")
                .font(.system(size: 18))
                .foregroundStyle(AppColor.accent)
                .accessibilityLabel(Text(verbatim: "Phonetic"))
            if !dynamicTypeSize.isAccessibilitySize {
                Text(verbatim: "Phonetic")
                    .font(.headline)
            }

            Spacer()

            Button("Skip", action: finishWalkthrough)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(minWidth: 44, minHeight: 44)
                .opacity(currentPage == .ready ? 0 : 1)
                .disabled(currentPage == .ready || isRequestingPermission)
                .accessibilityHidden(currentPage == .ready)
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, compact ? 0 : 8)
    }

    @ViewBuilder
    private func page(_ step: WalkthroughStep, landscape: Bool) -> some View {
        if landscape, !dynamicTypeSize.isAccessibilitySize {
            landscapePage(step)
        } else {
            portraitPage(step)
        }
    }

    private func portraitPage(_ step: WalkthroughStep) -> some View {
        ViewThatFits(in: .vertical) {
            pageContent(step, compact: false)
                .fixedSize(horizontal: false, vertical: true)
            pageContent(step, compact: true)
                .fixedSize(horizontal: false, vertical: true)
            ScrollView {
                pageContent(step, compact: true)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func landscapePage(_ step: WalkthroughStep) -> some View {
        ViewThatFits(in: .vertical) {
            landscapeContent(step, showsEmblem: true)
                .fixedSize(horizontal: false, vertical: true)
            landscapeContent(step, showsEmblem: false)
                .fixedSize(horizontal: false, vertical: true)
            ScrollView {
                landscapeContent(step, showsEmblem: false)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func landscapeContent(_ step: WalkthroughStep, showsEmblem: Bool) -> some View {
        HStack(alignment: .top, spacing: 32) {
            VStack(alignment: .leading, spacing: 16) {
                pageHeading(step, compact: true)

                if step == .quickSearch {
                    illustration(for: step, compact: true, showsEmblem: false)
                } else if showsEmblem {
                    emblem(step.symbol, color: step.accent, compact: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 12) {
                if step != .quickSearch {
                    illustration(for: step, compact: true, showsEmblem: false)
                }

                details(for: step)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 8)
    }

    private func pageContent(_ step: WalkthroughStep, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 16 : 24) {
            pageHeading(step, compact: compact)

            illustration(for: step, compact: compact)

            details(for: step)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.top, compact ? 8 : 16)
        .padding(.bottom, compact ? 12 : 16)
    }

    private func pageHeading(_ step: WalkthroughStep, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(step.title)
                .font(compact ? .title.bold() : .largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)

            Text(step.subtitle)
                .font(compact ? .subheadline : .body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func illustration(for step: WalkthroughStep, compact: Bool, showsEmblem: Bool = true) -> some View {
        switch step {
        case .contacts:
            VStack(spacing: compact ? 12 : 20) {
                if showsEmblem {
                    emblem(step.symbol, color: step.accent, compact: compact)
                }
                contactExample
            }
        case .notifications:
            VStack(spacing: compact ? 12 : 20) {
                if showsEmblem {
                    emblem(step.symbol, color: step.accent, compact: compact)
                }
                notificationExample
            }
        case .quickSearch:
            VStack(spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(step.accent)
                    Text(verbatim: "LMQ")
                        .font(.title3.monospaced().weight(.medium))
                    Spacer()
                    if compact {
                        Text(verbatim: "林沐晴")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(18)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                if !compact {
                    contactExample
                }
            }
            .accessibilityElement(children: .combine)
        case .displayNames:
            VStack(spacing: compact ? 12 : 20) {
                if showsEmblem {
                    emblem(step.symbol, color: step.accent, compact: compact)
                }
                VStack(alignment: .leading, spacing: 20) {
                    Label("Short Name", systemImage: "person.crop.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("Prefer Nicknames")
                            .font(.headline)
                        Spacer(minLength: 12)
                        Text("Off")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(step.accent.opacity(0.12), in: Capsule())
                    }
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.white.opacity(0.08))
                }
            }
        case .ready:
            VStack(spacing: compact ? 12 : 20) {
                if showsEmblem {
                    emblem(step.symbol, color: step.accent, compact: compact)
                }
                contactExample
            }
        }
    }

    private func emblem(_ symbol: String, color: Color, compact: Bool) -> some View {
        let size: CGFloat = compact ? 64 : 120
        return ZStack {
            Circle()
                .strokeBorder(color.opacity(0.08), lineWidth: 1)
                .frame(width: size, height: size)
            Circle()
                .fill(color.opacity(0.08))
                .frame(width: size * 0.8, height: size * 0.8)
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: size * 0.6, height: size * 0.6)
            Image(systemName: symbol)
                .font(.system(size: compact ? 24 : 38, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, compact ? 4 : 8)
        .accessibilityHidden(true)
    }

    private var contactExample: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
            : AnyLayout(HStackLayout(spacing: 16))
        return layout {
            Text(verbatim: "林")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(AppColor.accent)
                .frame(width: 58, height: 58)
                .background(AppColor.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(verbatim: "林沐晴")
                    .font(.title3.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                PinyinExampleText()
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Text(verbatim: "LMQ")
                .font(.caption.monospaced().weight(.semibold))
                .foregroundStyle(AppColor.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppColor.accent.opacity(0.1), in: Capsule())
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.white.opacity(0.08))
        }
        .accessibilityElement(children: .combine)
    }

    private var notificationExample: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "character.book.closed.fill")
                    .foregroundStyle(AppColor.accent)
                    .frame(width: 30, height: 30)
                    .background(AppColor.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text(verbatim: "Phonetic")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Notification Preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Completed")
                    .font(.headline)
                Text("Your contacts have been updated.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.white.opacity(0.1))
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func details(for step: WalkthroughStep) -> some View {
        switch step {
        case .contacts:
            VStack(alignment: .leading, spacing: 16) {
                feature("Pinyin for easy sorting", symbol: "textformat.abc", color: step.accent)
                feature("Initials for quick searching", symbol: "magnifyingglass", color: step.accent)

                if contactsAuthorization == .denied {
                    Button("Open App Settings", action: openAppSettings)
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 44)
                }
            }
        case .notifications:
            feature("Notifications are optional", symbol: "checkmark.circle", color: step.accent)
        case .quickSearch:
            VStack(alignment: .leading, spacing: 12) {
                Text("Save initials to")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                searchOption(title: String(localized: "Nickname"), isSelected: enableNickname) {
                    enableNickname = true
                    enableCustomName = false
                }

                if dynamicTypeSize.isAccessibilitySize {
                    ForEach(quickSearchOptions, id: \.rawValue) { option in
                        searchOption(option)
                    }
                } else {
                    Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                        GridRow {
                            searchOption(.notes, fillsRowHeight: true)
                            searchOption(.prefix, fillsRowHeight: true)
                        }
                        GridRow {
                            searchOption(.suffix, fillsRowHeight: true)
                            searchOption(.middleName, fillsRowHeight: true)
                        }
                    }
                }
            }
        case .displayNames:
            VStack(alignment: .leading, spacing: 16) {
                Text(contactsSettingsInstructions)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                feature("Keep contact names on display", symbol: "checkmark.circle", color: step.accent)
            }
        case .ready:
            VStack(alignment: .leading, spacing: 16) {
                feature("Tap once to add pinyin", symbol: "hand.tap", color: step.accent)
                feature("Double-tap or hold to clear fields", symbol: "arrow.uturn.backward", color: step.accent)
                feature("Skip selected contacts with the whitelist", symbol: "star", color: step.accent)
            }
        }
    }

    private var contactsSettingsInstructions: LocalizedStringKey {
        if #available(iOS 18.0, *) {
            return "Open Settings → Apps → Contacts → Short Name.\nTurn off Prefer Nicknames."
        }
        return "Open Settings → Contacts → Short Name.\nTurn off Prefer Nicknames."
    }

    private func feature(_ title: LocalizedStringKey, symbol: String, color: Color) -> some View {
        Label {
            Text(title)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .frame(width: 24)
        }
        .font(.subheadline)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func searchOption(_ option: QuickSearch, fillsRowHeight: Bool = false) -> some View {
        searchOption(title: option.key, isSelected: enableCustomName && quickSearchKeyRawValue == option.rawValue, fillsRowHeight: fillsRowHeight) {
            enableNickname = false
            enableCustomName = true
            quickSearchKeyRawValue = option.rawValue
        }
    }

    private func searchOption(title: String, isSelected: Bool, fillsRowHeight: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppColor.accent : Color.secondary.opacity(0.5))
            }
            .foregroundStyle(.primary)
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 52, maxHeight: fillsRowHeight ? .infinity : nil)
            .background(isSelected ? AppColor.accent.opacity(0.1) : .white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(isSelected ? AppColor.accent.opacity(0.6) : .white.opacity(0.08))
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func footer(compact: Bool) -> some View {
        if compact, !dynamicTypeSize.isAccessibilitySize {
            HStack(spacing: 20) {
                pageIndicator
                Spacer(minLength: 8)

                if currentPage == .notifications, notificationAuthorization == .notDetermined {
                    notificationSkipButton
                }

                navigationControls
                    .frame(maxWidth: 360)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 8)
        } else {
            VStack(spacing: compact ? 10 : 16) {
                pageIndicator

                navigationControls

                if currentPage == .notifications, notificationAuthorization == .notDetermined {
                    notificationSkipButton
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, compact ? 8 : 12)
            .padding(.bottom, compact ? 8 : 12)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(WalkthroughStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(step == currentPage ? AppColor.accent : .white.opacity(0.14))
                    .frame(width: step == currentPage ? 28 : 7, height: 7)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Step \(currentPage.rawValue + 1) of \(WalkthroughStep.allCases.count)"))
    }

    private var notificationSkipButton: some View {
        Button("Not Now", action: goForward)
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
            .frame(minHeight: 44)
            .disabled(isRequestingPermission)
    }

    @ViewBuilder
    private var navigationControls: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 12) {
                navigationButtons
            }
        } else {
            navigationButtons
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if currentPage != .contacts {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 20, height: 24)
                }
                .compatibleGlass()
                .buttonBorderShape(.circle)
                .transition(.opacity)
                .accessibilityLabel(Text("Previous Step"))
            }

            Button(action: continueWalkthrough) {
                HStack(spacing: 12) {
                    Text(primaryButtonTitle)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                    if isRequestingPermission {
                        ProgressView()
                            .tint(AppColor.onAccent)
                    } else if !dynamicTypeSize.isAccessibilitySize {
                        Image(systemName: currentPage == .ready ? "checkmark" : "arrow.right")
                            .contentTransition(.opacity)
                    }
                }
                .font(.headline)
                .foregroundStyle(AppColor.onAccent)
                .frame(maxWidth: .infinity, minHeight: 24)
            }
            .compatibleGlassProminent()
            .tint(AppColor.accent)
        }
        .controlSize(.large)
        .buttonBorderShape(.capsule)
        .disabled(isRequestingPermission)
    }

    private var primaryButtonTitle: LocalizedStringKey {
        if currentPage == .ready {
            return "Get Started"
        }
        if currentPage == .contacts, contactsAuthorization == .notDetermined {
            return "Allow Contacts"
        }
        if currentPage == .notifications, notificationAuthorization == .notDetermined {
            return "Enable Notifications"
        }
        return "Continue"
    }

    private func continueWalkthrough() {
        switch currentPage {
        case .contacts where contactsAuthorization == .notDetermined:
            isRequestingPermission = true
            Task {
                _ = await AppDelegate.shared.requestContactsAccess()
                contactsAuthorization = CNContactStore.authorizationStatus(for: .contacts)
                isRequestingPermission = false
                goForward()
            }
        case .notifications where notificationAuthorization == .notDetermined:
            isRequestingPermission = true
            Task {
                _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                await refreshPermissions()
                isRequestingPermission = false
                goForward()
            }
        case .ready:
            finishWalkthrough()
        default:
            goForward()
        }
    }

    private func goForward() {
        guard let next = WalkthroughStep(rawValue: currentPage.rawValue + 1) else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
            currentPage = next
        }
    }

    private func goBack() {
        guard let previous = WalkthroughStep(rawValue: currentPage.rawValue - 1) else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
            currentPage = previous
        }
    }

    private func refreshPermissions() async {
        contactsAuthorization = CNContactStore.authorizationStatus(for: .contacts)
        notificationAuthorization = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(settingsURL)
    }

    private func finishWalkthrough() {
        UserDefaults.standard.set(true, forKey: displayedWalthroughKey)
        dismiss()
    }
}

private enum WalkthroughStep: Int, CaseIterable {
    case contacts, notifications, quickSearch, displayNames, ready

    var symbol: String {
        switch self {
        case .contacts: "person.crop.rectangle.stack.fill"
        case .notifications: "bell.badge.fill"
        case .quickSearch: "magnifyingglass"
        case .displayNames: "person.text.rectangle"
        case .ready: "checkmark.seal.fill"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .contacts: "Every name,\nin its place."
        case .notifications: "We'll let you\nknow."
        case .quickSearch: "A few letters.\nFound."
        case .displayNames: "Keep names.\nOne small change."
        case .ready: "You're all set."
        }
    }

    var subtitle: LocalizedStringKey {
        switch self {
        case .contacts: "Add pinyin to Chinese names for alphabetical sorting and easier search."
        case .notifications: "Follow progress as Phonetic updates your contacts. If system progress isn't available, you can enable notifications for completion alerts."
        case .quickSearch: "Search for LMQ to find 林沐晴. Choose a contact field for search initials."
        case .displayNames: "If you save search initials in Nickname, turn off Prefer Nicknames to keep contact names on display."
        case .ready: "Return to the main screen and tap once to add pinyin to your contacts."
        }
    }

    var accent: Color {
        switch self {
        case .contacts, .ready: AppColor.accent
        case .notifications: AppColor.onboardingNotificationAccent
        case .quickSearch: AppColor.onboardingQuickSearchAccent
        case .displayNames: AppColor.onboardingDisplayNamesAccent
        }
    }
}
