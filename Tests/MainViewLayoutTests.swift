@testable import Phonetic
import SwiftUI
import Testing
import UIKit

@MainActor
private final class LayoutProcessingService: ContactProcessingService {
    var isProcessing = false
    var messageOfCurrentKeysNeedToBeCleaned: String {
        ""
    }

    func execute(resultHandler: @escaping PhoneticContacts.ResultHandler) async -> ContactOperationOutcome {
        .completed
    }

    func cleanMandarinLatinPhonetic(resultHandler: @escaping PhoneticContacts.ResultHandler) async -> ContactOperationOutcome {
        .completed
    }
}

@MainActor
private final class LayoutHost<Content: View>: UIHostingController<Content> {
    var hasAppeared = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasAppeared = true
    }
}

@MainActor
@Suite(.serialized)
struct MainViewLayoutTests {
    @Test("Home reflows to fit landscape and keeps accessibility overflow above the actions",
          arguments: [CGSize(width: 852, height: 393), CGSize(width: 393, height: 852)], [false, true])
    static func contentViewport(size: CGSize, accessibilitySize: Bool) async throws {
        let service = LayoutProcessingService()
        let state = AppState(contactProvider: { service }, requestAccess: { true },
                             waitForCompletion: {}, dismissPresentedModals: { $0() })
        state.execute()
        try await waitUntil { state.lastOutcome == .completed && !state.isProcessing }
        let root = MainView()
            .environmentObject(state)
            .environment(\.dynamicTypeSize, accessibilitySize ? .accessibility3 : .large)
        let host = LayoutHost(rootView: root)
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = host
        window.isHidden = false
        defer { window.isHidden = true; window.rootViewController = nil }
        host.view.frame = window.bounds
        window.layoutIfNeeded()

        try await waitUntil {
            window.layoutIfNeeded()
            return host.hasAppeared && scrollViews(in: host.view).contains { $0.bounds.height > 0 && $0.contentSize.height > 0 }
        }
        let scroll = try #require(scrollViews(in: host.view).first)
        let viewport = scroll.convert(scroll.bounds, to: host.view)
        #expect(viewport.height > 0)
        #expect(viewport.minY >= 0)
        #expect(viewport.maxY <= host.view.bounds.maxY - 88, "The content viewport must reserve the bottom actions' space")
        #expect(!scroll.clipsToBounds, "Scrolling must not cut content off at a hard viewport edge")
        if accessibilitySize {
            #expect(scroll.contentSize.height > scroll.bounds.height, "Large accessibility content must remain reachable")
        } else {
            #expect(scroll.contentSize.height <= scroll.bounds.height + 1, "Standard-size content must fit without vertical scrolling, including in landscape")
        }
    }

    private static func scrollViews(in view: UIView) -> [UIScrollView] {
        (view as? UIScrollView).map { [$0] } ?? view.subviews.flatMap { scrollViews(in: $0) }
    }
}
