// Created by Augus on 9/28/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import Contacts
import ContactsUI
import SwiftUI
import UIKit

struct WhitelistView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var contacts: [CNContact] = []
    @State private var searchText: String = ""
    @State private var selectedSegment: Int = 0 // 0: All, 1: Whitelists
    @State private var selectedContact: CNContact?
    @State private var showTipsPopover = false
    @State private var showRemoveAllConfirmation = false
    @State private var whitelistSet: Set<String> = []
    @State private var isLoading = true
    @State private var accessDenied = false
    @State private var authorizationStatus: CNAuthorizationStatus = .notDetermined
    @State private var showContactAccessPicker = false
    @State private var refreshCoordinator = WhitelistContactRefreshCoordinator()
    @State private var errorMessage: String?

    private var filteredContacts: [CNContact] {
        var result = contacts

        if selectedSegment == 1 {
            result = result.filter { whitelistSet.contains($0.identifier) }
        }

        if !searchText.isEmpty {
            result = result.filter { $0.matchesWhitelistSearch(searchText) }
        }

        return result
    }

    var body: some View {
        if #available(iOS 18.0, *) {
            whitelistContent
                .contactAccessPicker(isPresented: $showContactAccessPicker) { _ in
                    refreshContacts()
                }
        } else {
            whitelistContent
        }
    }

    private var whitelistContent: some View {
        VStack(spacing: 0) {
            // Segmented control
            Picker("Contact List", selection: $selectedSegment) {
                Text("All").tag(0)
                Text("Whitelist").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if isLoading {
                DelayedProgressView("Loading Contacts")
            } else if accessDenied {
                ContentUnavailableView {
                    Label("Contacts Access Needed", systemImage: "person.crop.circle.badge.exclamationmark")
                } description: {
                    Text("Allow contacts access in Settings to view and manage your whitelist.")
                } actions: {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                }
            } else if let errorMessage, contacts.isEmpty {
                ContentUnavailableView {
                    Label("Contacts Unavailable", systemImage: "exclamationmark.triangle")
                } description: { Text(errorMessage) } actions: {
                    Button("Try Again") { refreshContacts() }
                }
            } else if WhitelistAccessPresentation.showLimitedEmptyState(status: authorizationStatus, visibleCount: contacts.count) {
                ContentUnavailableView {
                    Label("Limited Contacts Access", systemImage: "person.crop.circle.badge.exclamationmark")
                } description: {
                    Text("Only contacts shared with Phonetic are visible. Choose more contacts to manage your whitelist.")
                } actions: {
                    Button("Choose Contacts") { showContactAccessPicker = true }
                }
            } else {
                contactList
                    .contentMargins(.top, 8, for: .scrollContent)
                    .overlay {
                        if filteredContacts.isEmpty {
                            if !searchText.isEmpty {
                                ContentUnavailableView.search(text: searchText)
                            } else if selectedSegment == 1 {
                                ContentUnavailableView("No Whitelisted Contacts", systemImage: "star", description: Text("Tap a star in All to add a contact to your whitelist."))
                            } else {
                                ContentUnavailableView("No Contacts", systemImage: "person.crop.circle")
                            }
                        }
                    }
            }
        }
        .background(AppColor.pageBackground)
        .searchable(text: $searchText, prompt: Text("Search"))
        .navigationTitle("Whitelist")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Contacts Unavailable", isPresented: Binding(
            get: { errorMessage != nil && !contacts.isEmpty },
            set: {
                if !$0 {
                    errorMessage = nil
                }
            }
        )) {
            Button("Try Again") { refreshContacts() }
            Button("Cancel", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if WhitelistAccessPresentation.isLimited(authorizationStatus), !contacts.isEmpty {
                    Button("Choose Contacts", systemImage: "person.crop.circle.badge.plus") {
                        showContactAccessPicker = true
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if selectedSegment == 1 {
                    if !whitelistSet.isEmpty {
                        Button(role: .destructive, action: { showRemoveAllConfirmation = true }) {
                            Label("Clear Whitelist", systemImage: "trash")
                        }
                        .tint(Color.primary)
                        .confirmationDialog("Clear the whitelist?", isPresented: $showRemoveAllConfirmation, titleVisibility: .visible) {
                            Button("Clear", role: .destructive) {
                                whitelistSet.removeAll()
                                UserDefaults.standard.removeObject(forKey: kWhitelistIdentifiersKey)
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This only clears the whitelist. Your contacts won't be deleted.")
                        }
                    }
                } else {
                    Button {
                        showTipsPopover = true
                    } label: {
                        Label("Tips", systemImage: Constants.infoSymbolName)
                    }
                    .tint(Color.primary)
                    .popover(isPresented: $showTipsPopover, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                        ScrollView {
                            Text("""
                                Phonetic skips whitelisted contacts when adding pinyin or clearing fields.

                                Tap a star to add or remove a contact from the whitelist. Tap a contact to edit its fields manually.
                                """)
                                .multilineTextAlignment(.leading)
                                .padding()
                        }
                        .frame(width: 220, alignment: .leading)
                        .font(.callout)
                        .presentationCompactAdaptation(.popover)
                    }
                }
            }
        }
        .sheet(item: Binding<IdentifiableContact?>(
            get: { selectedContact.map { IdentifiableContact(contact: $0) } },
            set: { selectedContact = $0?.contact }
        )) { item in
            EditableContactView(contact: item.contact) {
                refreshContacts()
            }
        }
        .task {
            loadWhitelist()
            refreshContacts()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                refreshContacts()
            }
        }
        .onDisappear {
            refreshCoordinator.cancel()
        }
    }

    private var contactList: some View {
        List {
            ForEach(filteredContacts, id: \.identifier) { contact in
                contactRow(contact)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 8))
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func contactRow(_ contact: CNContact) -> some View {
        HStack(spacing: 12) {
            if selectedSegment == 1 {
                Button {
                    selectedContact = contact
                } label: {
                    contactIdentity(contact)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(contact.whitelistDisplayName))
                .accessibilityValue(Text(verbatim: contactAccessibilityDetails(contact)))
                .accessibilityHint(Text("Edit Contact"))
            } else {
                contactIdentity(contact)
                Spacer()
            }

            // Whitelist toggle
            let isWhitelisted = whitelistSet.contains(contact.identifier)
            Button(action: {
                toggleWhitelist(contact.identifier)
            }) {
                Image(systemName: isWhitelisted ? "star.fill" : "star")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(isWhitelisted ? AppColor.accent : Color.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isWhitelisted ? Text("Remove from Whitelist") : Text("Add to Whitelist"))
            .accessibilityValue(Text(contact.whitelistDisplayName))
            .accessibilityAddTraits(isWhitelisted ? .isSelected : [])
        }
    }

    private func contactIdentity(_ contact: CNContact) -> some View {
        HStack(spacing: 12) {
            if let imageData = contact.thumbnailImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .accessibilityHidden(true)
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(contact.whitelistDisplayName)
                    .font(.body.weight(.medium))

                let phonetic = "\(contact.phoneticFamilyName) \(contact.phoneticGivenName)".trimmingCharacters(in: .whitespaces)
                if !phonetic.isEmpty {
                    Text(phonetic)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let key = PhoneticContacts.shared.ContactKeyForQuickSearch,
                   let brief = contact.quickSearchBriefName(key), !brief.isEmpty {
                    Text(brief)
                        .font(.caption)
                        .foregroundStyle(AppColor.accent)
                }
            }
        }
        .contentShape(Rectangle())
    }

    private func contactAccessibilityDetails(_ contact: CNContact) -> String {
        var details: [String] = []
        if !contact.phoneticFamilyName.isEmpty {
            details.append("\(String(localized: "Phonetic last name")): \(contact.phoneticFamilyName)")
        }
        if !contact.phoneticGivenName.isEmpty {
            details.append("\(String(localized: "Phonetic first name")): \(contact.phoneticGivenName)")
        }
        if let key = PhoneticContacts.shared.ContactKeyForQuickSearch,
           let brief = contact.quickSearchBriefName(key), !brief.isEmpty {
            details.append("\(String(localized: "Quick Search Text")): \(brief)")
        }
        return details.joined(separator: ", ")
    }

    private func loadWhitelist() {
        let array = UserDefaults.standard.array(forKey: kWhitelistIdentifiersKey) as? [String] ?? []
        whitelistSet = Set(array)
    }

    private func toggleWhitelist(_ id: String) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
            if whitelistSet.contains(id) {
                whitelistSet.remove(id)
            } else {
                whitelistSet.insert(id)
            }
        }
        UserDefaults.standard.set(Array(whitelistSet), forKey: kWhitelistIdentifiersKey)
    }

    private func refreshContacts() {
        refreshCoordinator.schedule { isLatest in
            await loadContacts(isLatest: isLatest)
        }
    }

    private func loadContacts(isLatest: @escaping @MainActor () -> Bool) async {
        guard isLatest() else { return }
        isLoading = contacts.isEmpty
        errorMessage = nil
        defer {
            if isLatest() {
                isLoading = false
            }
        }
        do {
            let engine = PhoneticContacts.shared
            let status = CNContactStore.authorizationStatus(for: .contacts)
            let granted: Bool = if status == .notDetermined {
                try await engine.contactStore.requestAccess(for: .contacts)
            } else if #available(iOS 18.0, *), status == .limited {
                true
            } else {
                status == .authorized
            }
            try Task.checkCancellation()
            guard isLatest() else { return }
            if !granted {
                authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
                accessDenied = true
                contacts = []
                return
            }
            let fetched = try await engine.fetchWhitelistContacts()
            try Task.checkCancellation()
            guard isLatest() else { return }
            authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            accessDenied = false
            contacts = fetched
        } catch is CancellationError {
            return
        } catch {
            guard isLatest() else { return }
            let status = CNContactStore.authorizationStatus(for: .contacts)
            authorizationStatus = status
            if status == .denied || status == .restricted {
                accessDenied = true
                contacts = []
            } else {
                accessDenied = false
                errorMessage = String(localized: "Your contacts could not be loaded. Try again.")
            }
        }
    }
}

private struct IdentifiableContact: Identifiable {
    var id: String {
        contact.identifier
    }

    let contact: CNContact
}

@MainActor
final class WhitelistContactRefreshCoordinator {
    private var generation = 0
    private var activeTask: Task<Void, Never>?

    @discardableResult
    func schedule(_ work: @escaping @MainActor (@escaping @MainActor () -> Bool) async -> Void) -> Task<Void, Never> {
        generation &+= 1
        let requestedGeneration = generation
        activeTask?.cancel()
        let task = Task { [weak self] in
            await work { [weak self] in
                self?.generation == requestedGeneration && !Task.isCancelled
            }
        }
        activeTask = task
        return task
    }

    func cancel() {
        generation &+= 1
        activeTask?.cancel()
        activeTask = nil
    }
}

enum WhitelistAccessPresentation {
    static func isLimited(_ status: CNAuthorizationStatus) -> Bool {
        if #available(iOS 18.0, *) {
            return status == .limited
        }
        return false
    }

    static func showLimitedEmptyState(status: CNAuthorizationStatus, visibleCount: Int) -> Bool {
        isLimited(status) && visibleCount == 0
    }
}
