// Created by Augus on 10/27/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import OSLog
import UserNotifications

@MainActor
final class AppBadge {
    static let shared = AppBadge()

    private let logger = Logger(subsystem: "com.iAugus.Phonetic", category: "AppBadge")
    private let writeCount: @MainActor (Int) async throws -> Void
    private var pendingCount: Int?
    private var isUpdating = false

    init(writeCount: @escaping @MainActor (Int) async throws -> Void = { count in
        try await UNUserNotificationCenter.current().setBadgeCount(count)
    }) {
        self.writeCount = writeCount
    }

    func setCount(_ count: Int) {
        pendingCount = max(0, count)
        guard !isUpdating else { return }
        isUpdating = true

        // Badge writes are asynchronous. Keep one in flight and retain only the latest requested
        // value, so a foreground reset cannot be overtaken by an older background progress write.
        Task {
            while let count = pendingCount {
                pendingCount = nil
                do {
                    try await writeCount(count)
                } catch {
                    logger.error("Updating app badge failed: \(error.localizedDescription)")
                }
            }
            isUpdating = false
        }
    }
}
