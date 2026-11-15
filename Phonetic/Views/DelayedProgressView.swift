import SwiftUI

struct DelayedProgressView: View {
    let title: LocalizedStringKey
    @State private var isVisible = false

    init(_ title: LocalizedStringKey) {
        self.title = title
    }

    var body: some View {
        ProgressView(title)
            .controlSize(.large)
            .tint(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(isVisible ? 1 : 0)
            .accessibilityHidden(!isVisible)
            .task {
                isVisible = false
                do { try await Task.sleep(for: .milliseconds(350)) }
                catch { return }
                guard !Task.isCancelled else { return }
                isVisible = true
            }
            .onDisappear { isVisible = false }
    }
}
