import SwiftUI

struct ContactVersionsView: View {
    @State private var history: ContactVersionHistory?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var versions: [ContactVersion] {
        history?.versions ?? []
    }

    private var earliestOrdinal: Int {
        history?.earliestOrdinal ?? 0
    }

    var body: some View {
        List {
            if let errorMessage, history == nil, !isLoading {
                ContentUnavailableView {
                    Label("History Unavailable", systemImage: "exclamationmark.triangle")
                } description: { Text(errorMessage) } actions: {
                    Button("Try Again") { Task { await load() } }
                }
            } else if history != nil {
                if let history {
                    storageSection(history)
                }
                if versions.isEmpty {
                    if earliestOrdinal == 0 {
                        ContentUnavailableView("No Changes Yet", systemImage: "clock.arrow.circlepath",
                                               description: Text("Changes made by Phonetic will appear here. You can preview and restore an earlier version."))
                    } else {
                        ContentUnavailableView("Older History Cleared", systemImage: "clock.arrow.circlepath",
                                               description: Text("New changes will appear here. Earlier deleted history cannot be restored."))
                    }
                }
                if !versions.isEmpty || earliestOrdinal > 0 {
                    versionSection
                }
            }
        }
        .overlay {
            if history == nil, isLoading || errorMessage == nil {
                DelayedProgressView("Loading History")
            }
        }
        .navigationTitle("Version History")
        .refreshable { await load() }
        .task {
            if history == nil {
                await load()
            }
        }
        .alert("History Unavailable", isPresented: Binding(
            get: { history != nil && errorMessage != nil },
            set: {
                if !$0 {
                    errorMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func storageSection(_ history: ContactVersionHistory) -> some View {
        let used = ByteCountFormatter.string(fromByteCount: history.usedBytes, countStyle: .file)
        let limit = ByteCountFormatter.string(fromByteCount: history.limitBytes, countStyle: .file)
        let fraction = Double(history.usedBytes) / Double(history.limitBytes)
        return Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(used) of \(limit)")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    Text(fraction, format: .percent.precision(.fractionLength(0)))
                        .font(.subheadline.weight(.medium)).monospacedDigit()
                }
                ProgressView(value: min(fraction, 1))
                    .tint(AppColor.accent)
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("History Storage")
            .accessibilityValue(Text("\(used) of \(limit)"))
        } header: { Text("History Storage") } footer: {
            Text("Oldest history is removed automatically when space is needed. Your contacts are not changed.")
        }
    }

    private var versionSection: some View {
        Section {
            ForEach(versions) { version in
                NavigationLink {
                    ContactRestoreView(targetOrdinal: version.ordinal) { Task { await load() } }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Version \(version.ordinal)").font(.headline)
                            Spacer()
                            if version.id == versions.first?.id {
                                Text("Latest").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Text(version.kind.title)
                        Text(version.createdAt.formatted(date: .abbreviated, time: .standard))
                            .font(.caption).foregroundStyle(.secondary)
                        Text("Contacts: \(version.contactCount) · Fields: \(version.fieldCount)")
                            .font(.caption).foregroundStyle(.secondary)
                        if version.status != .completed {
                            Text(version.status.title).font(.caption).foregroundStyle(.secondary)
                        }
                        if let target = version.targetOrdinal {
                            Text("Restored toward Version \(target)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            NavigationLink {
                ContactRestoreView(targetOrdinal: earliestOrdinal) { Task { await load() } }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    if earliestOrdinal == 0 {
                        Text("Before First Change")
                    } else {
                        Text("Earliest Available Version")
                    }
                    Text("Version \(earliestOrdinal)").font(.caption).foregroundStyle(.secondary)
                }
            }
        } footer: {
            Text("Only fields changed by Phonetic can be restored. Restoring creates a new version. History stays on this device and is removed if you delete the app.")
        }
    }

    @MainActor private func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do { history = try await ContactVersionStore.shared.overview() } catch { errorMessage = (error as? ContactVersionError ?? .historyUnavailable).localizedDescription }
    }
}

private struct ContactRestoreView: View {
    let targetOrdinal: Int
    let onRestored: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var preview: ContactRestorePreview?
    @State private var selected: Set<String> = []
    @State private var errorMessage: String?
    @State private var isRestoring = false
    @State private var showConfirmation = false
    @State private var showResult = false
    @State private var resultMessage = ""
    @State private var progress = 0.0

    private var groups: [(key: String, value: [ContactRestoreEntry])] {
        Dictionary(grouping: preview?.entries ?? [], by: { $0.change.contactID })
            .sorted { ($0.value.first?.change.contactName ?? "", $0.key) < ($1.value.first?.change.contactName ?? "", $1.key) }
    }

    private var hasSelectedConflicts: Bool {
        preview?.entries.contains { $0.isConflict && selected.contains($0.id) } == true
    }

    private var selectedFieldCount: Int {
        preview?.entries.filter { selected.contains($0.id) && $0.current != nil }.count ?? 0
    }

    var body: some View {
        Group {
            if preview == nil, errorMessage == nil {
                DelayedProgressView("Preparing Preview")
            } else {
                List {
                    Section {
                        Text("Version \(targetOrdinal)").font(.headline)
                        Text("Review each field before restoring. Contacts that were deleted or are no longer accessible cannot be restored.")
                            .foregroundStyle(.secondary)
                    }
                    if let errorMessage {
                        ContentUnavailableView {
                            Label("Preview Unavailable", systemImage: "exclamationmark.triangle")
                        } description: { Text(errorMessage) } actions: {
                            Button("Try Again") { Task { await load() } }
                        }
                    } else if let preview {
                        if preview.entries.isEmpty {
                            ContentUnavailableView("No Fields to Restore", systemImage: "checkmark.circle",
                                                   description: Text("There are no remaining Phonetic changes to undo after this version."))
                        } else {
                            ForEach(groups, id: \.key) { group in
                                Section {
                                    ForEach(group.value) { entry in
                                        restoreRow(entry)
                                    }
                                } header: { Text(group.value.first?.change.contactName ?? "").textCase(nil) }
                            }
                            Section {
                                Text("Fields changed outside Phonetic are unselected. Select them only if you want to replace their current values. Fields changed again after this preview will be skipped.")
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .disabled(isRestoring)
        .navigationTitle("Restore Preview")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isRestoring)
        .interactiveDismissDisabled(isRestoring)
        .toolbar {
            if isRestoring {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Stop") { PhoneticContacts.shared.isProcessing = false }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isRestoring || (errorMessage == nil && preview?.entries.contains(where: { $0.current != nil }) == true) {
                restoreControls
                    .frame(maxWidth: 480)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
            }
        }
        .alert("Restore Result", isPresented: $showResult) {
            Button("OK") { onRestored(); dismiss() }
        } message: { Text(resultMessage) }
        .task { await load() }
    }

    @ViewBuilder private var restoreControls: some View {
        if isRestoring {
            if #available(iOS 26.0, *) {
                restoreProgress.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                restoreProgress.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        } else {
            VStack(spacing: 8) {
                Text("Selected Fields: \(selectedFieldCount)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if selectedFieldCount == 0 {
                    Text("Select at least one field to restore.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Button { showConfirmation = true } label: {
                    Label("Restore Selected Fields", systemImage: "arrow.uturn.backward")
                        .font(.headline)
                        .foregroundStyle(AppColor.onAccent)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 24)
                }
                .compatibleGlassProminent()
                .controlSize(.large)
                .buttonBorderShape(.capsule)
                .tint(AppColor.accent)
                .disabled(selectedFieldCount == 0)
                .confirmationDialog("Restore These Fields?", isPresented: $showConfirmation, titleVisibility: .visible) {
                    Button("Restore", role: .destructive) { restore() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    if hasSelectedConflicts {
                        Text("This includes fields changed outside Phonetic. Their current values will be replaced. A new version will record the restore.")
                    } else {
                        Text("The selected fields will be restored. A new version will record the restore.")
                    }
                }
            }
        }
    }

    private var restoreProgress: some View {
        ProgressView("Restoring Contact Fields", value: progress)
            .tint(.secondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
    }

    private func restoreRow(_ entry: ContactRestoreEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(entry.change.field.title, isOn: Binding(
                get: { selected.contains(entry.id) },
                set: {
                    if $0 {
                        selected.insert(entry.id)
                    } else {
                        selected.remove(entry.id)
                    }
                }
            ))
            .disabled(entry.current == nil)
            .tint(AppColor.accent)
            if let current = entry.current {
                valueRow("Current", value: current)
                valueRow("Restore To", value: entry.change.before)
                if entry.isConflict {
                    Label("Changed outside Phonetic or not verified", systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Label("Contact unavailable — skipped", systemImage: "person.crop.circle.badge.exclamationmark")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func valueRow(_ title: LocalizedStringKey, value: ContactVersionValue) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            if value.summary.isEmpty {
                Text("Empty").foregroundStyle(.secondary)
            } else {
                Text(verbatim: value.summary).textSelection(.enabled)
            }
        }
    }

    @MainActor private func load() async {
        errorMessage = nil
        preview = nil
        selected = []
        do {
            let value = try await ContactVersionStore.shared.preview(targetOrdinal: targetOrdinal)
            preview = value
            selected = Set(value.entries.filter { !$0.isConflict && $0.current != nil }.map(\.id))
        } catch { errorMessage = (error as? ContactVersionError ?? .historyUnavailable).localizedDescription }
    }

    private func restore() {
        guard let preview, !isRestoring else { return }
        let selectedFields = selected
        let selectedCount = preview.entries.filter { selectedFields.contains($0.id) && $0.current != nil }.count
        guard selectedCount > 0 else { return }
        isRestoring = true
        progress = 0
        Task {
            let (outcome, skipped) = await PhoneticContacts.shared.restoreVersion(preview, selected: selectedFields) { checked, total in
                progress = Double(checked) / Double(max(total, 1))
            }
            isRestoring = false
            switch outcome {
            case .completed:
                if skipped == 0 {
                    resultMessage = String(localized: "The selected fields have been restored.")
                } else if skipped >= selectedCount {
                    resultMessage = String(localized: "No fields were restored. Fields skipped because they changed or became unavailable: \(skipped).")
                } else {
                    resultMessage = String(localized: "Restore finished. Fields skipped because they changed or became unavailable: \(skipped).")
                }
            case .stopped:
                resultMessage = String(localized: "Stopped. Any changes already made are recorded in Version History.")
            case .failed(let error): resultMessage = error.localizedDescription
            }
            showResult = true
        }
    }
}
