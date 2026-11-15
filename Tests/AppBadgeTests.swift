@testable import Phonetic
import Foundation
import Testing

@MainActor
private final class BadgeWriter {
    private(set) var counts: [Int] = []
    private var completions: [CheckedContinuation<Void, Error>] = []

    func write(_ count: Int) async throws {
        counts.append(count)
        try await withCheckedThrowingContinuation { completions.append($0) }
    }

    func waitForWrites(_ count: Int) async throws {
        try await waitUntil { self.counts.count >= count }
    }

    func completeNext(throwing error: Error? = nil) {
        let completion = completions.removeFirst()
        if let error {
            completion.resume(throwing: error)
        } else {
            completion.resume()
        }
    }
}

@MainActor
struct AppBadgeTests {
    @Test
    static func foregroundResetWins() async throws {
        let writer = BadgeWriter()
        let badge = AppBadge(writeCount: writer.write)
        badge.setCount(10)
        try await writer.waitForWrites(1)

        badge.setCount(20)
        badge.setCount(30)
        badge.setCount(0)
        #expect(writer.counts == [10], "Only one badge write may be in flight")
        writer.completeNext()
        try await writer.waitForWrites(2)
        #expect(writer.counts == [10, 0], "The latest reset must replace queued progress")
        writer.completeNext()

        // Allow the worker to stop before requesting a later background update.
        for _ in 0..<10 {
            await Task.yield()
        }
        badge.setCount(5)
        try await writer.waitForWrites(3)
        #expect(writer.counts == [10, 0, 5], "Badge writes must restart after draining")
        writer.completeNext()
    }

    @Test
    static func failureRecovery() async throws {
        enum TestError: Error { case rejected }
        let writer = BadgeWriter()
        let badge = AppBadge(writeCount: writer.write)
        badge.setCount(80)
        try await writer.waitForWrites(1)
        badge.setCount(0)
        writer.completeNext(throwing: TestError.rejected)
        try await writer.waitForWrites(2)
        #expect(writer.counts == [80, 0], "A failed write must not strand the pending reset")
        writer.completeNext()
    }

    @Test
    static func negativeCount() async throws {
        let writer = BadgeWriter()
        let badge = AppBadge(writeCount: writer.write)
        badge.setCount(-1)
        try await writer.waitForWrites(1)
        #expect(writer.counts == [0], "Negative badge values must clear the badge")
        writer.completeNext()
    }

    @Test
    static func environment() {
#if DEBUG
        #expect(AppEnvironment.current == .development)
#else
        #expect(AppEnvironment.current == .production, "Release builds must disable development generators")
#endif
    }
}
