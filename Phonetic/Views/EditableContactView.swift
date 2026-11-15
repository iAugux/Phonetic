// Created by Augus on 9/28/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import Contacts
import SwiftUI

struct EditableContactView: View {
    @Environment(\.dismiss) private var dismiss
    let contact: CNContact
    var onSaved: (() -> Void)?

    @State private var phoneticFamilyName: String = ""
    @State private var phoneticGivenName: String = ""
    @State private var quickSearchKeyText: String = ""
    @State private var isSaving = false
    @State private var showSaveError = false
    @State private var saveError = ""
    @FocusState private var focusedField: Field?
    private enum Field: Hashable { case family, given, quickSearch }

    private var currentQuickSearchKey: String? {
        PhoneticContacts.shared.ContactKeyForQuickSearch
    }

    private func quickSearchStorageHint(for key: String) -> LocalizedStringKey? {
        switch key {
        case CNContactNicknameKey:
            return "Saves to the contact’s Nickname field."
        case CNContactNoteKey:
            return "Saves to the contact’s Notes field."
        case CNContactNamePrefixKey:
            return "Saves to the contact’s Name Prefix field."
        case CNContactNameSuffixKey:
            return "Saves to the contact’s Name Suffix field."
        case CNContactPhoneticMiddleNameKey:
            return "Saves to the contact’s Phonetic Middle Name field."
        default:
            return nil
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Contact Avatar
                        if let imageData = contact.thumbnailImageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 55, height: 55)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 55, height: 55)
                                .foregroundStyle(.secondary)
                        }

                        // Contact Name
                        Text(contact.whitelistDisplayName)
                            .font(.headline)

                        // Input fields
                        VStack(spacing: 16) {
                            // Phonetic last name
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Phonetic last name")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                TextField("Phonetic last name", text: $phoneticFamilyName, prompt: Text("Enter pronunciation"))
                                    .focused($focusedField, equals: .family)
                                    .autocorrectionDisabled()
                                    .textFieldStyle(.plain)
                                    .font(.subheadline)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 10)
                                    .background(AppColor.inputBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }

                            // Phonetic first name
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Phonetic first name")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                TextField("Phonetic first name", text: $phoneticGivenName, prompt: Text("Enter pronunciation"))
                                    .focused($focusedField, equals: .given)
                                    .autocorrectionDisabled()
                                    .textFieldStyle(.plain)
                                    .font(.subheadline)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 10)
                                    .background(AppColor.inputBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }

                            // Quick search key
                            if let key = currentQuickSearchKey {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Quick Search Text")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    TextField("Quick Search Text", text: $quickSearchKeyText, prompt: Text("Enter initials or a name"))
                                        .focused($focusedField, equals: .quickSearch)
                                        .autocorrectionDisabled()
                                        .textFieldStyle(.plain)
                                        .font(.subheadline)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 10)
                                        .background(AppColor.inputBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                    if let hint = quickSearchStorageHint(for: key) {
                                        Text(hint)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 24)
                }
                .disabled(isSaving)
                if isSaving {
                    ProgressView("Saving Contact")
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
            .interactiveDismissDisabled(isSaving)
            .alert("Unable to Update Contacts", isPresented: $showSaveError) {
                Button("Close") { onSaved?(); dismiss() }
                Button("Keep Editing", role: .cancel) {}
            } message: { Text(saveError) }
            .navigationTitle(contact.whitelistDisplayName)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Label("Close", systemImage: "xmark")
                    }
                    .tint(Color.primary)
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveContact()
                    }
                    .foregroundStyle(AppColor.accent)
                    .disabled(isSaving)
                }
            }
            .onAppear {
                phoneticFamilyName = contact.phoneticFamilyName
                phoneticGivenName = contact.phoneticGivenName
                if let key = currentQuickSearchKey {
                    quickSearchKeyText = contact.quickSearchBriefName(key) ?? ""
                }
            }
        }
    }

    private func saveContact() {
        guard let mutableContact = contact.mutableCopy() as? CNMutableContact else { return }
        mutableContact.setValue(phoneticFamilyName.trimmingCharacters(in: .whitespaces), forKey: CNContactPhoneticFamilyNameKey)
        mutableContact.setValue(phoneticGivenName.trimmingCharacters(in: .whitespaces), forKey: CNContactPhoneticGivenNameKey)

        if let key = currentQuickSearchKey {
            mutableContact.setValue(quickSearchKeyText.trimmingCharacters(in: .whitespaces), forKey: key)
        }

        focusedField = nil
        isSaving = true
        Task {
            let outcome = await PhoneticContacts.shared.saveEditedContact(original: contact, modified: mutableContact)
            isSaving = false
            switch outcome {
            case .completed:
                onSaved?()
                dismiss()
            case .stopped:
                saveError = String(localized: "Stopped. Any changes already made are recorded in Version History.")
                showSaveError = true
            case .failed(let error):
                saveError = error.localizedDescription
                showSaveError = true
            }
        }
    }
}
