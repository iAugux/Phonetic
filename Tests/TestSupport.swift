import Foundation
import Testing

@MainActor
func waitUntil(_ condition: () -> Bool, sourceLocation: SourceLocation = #_sourceLocation) async throws {
    let deadline = ContinuousClock.now.advanced(by: .seconds(5))
    while !condition() {
        try #require(ContinuousClock.now < deadline, "Timed out waiting for asynchronous state", sourceLocation: sourceLocation)
        try Task.checkCancellation()
        await Task.yield()
    }
}
