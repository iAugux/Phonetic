// Created by Augus on 9/28/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI

@main
struct PhoneticApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared

    init() {
        // Migrate before constructing any @AppStorage-backed views or handling launch actions.
        // A deferred onAppear migration could expose legacy ON flags to UI or contact processing.
        SettingsMigration.migrate()
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .tint(AppColor.accent)
                .onAppear {
                    appState.setup()
                }
                .onOpenURL { url in
                    appState.handleOpenURL(url)
                }
        }
    }
}
