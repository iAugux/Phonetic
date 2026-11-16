import Contacts
import Foundation

enum ContactVersionError: Error, LocalizedError, Sendable, Equatable {
    case historyUnavailable, contactsChanged, saveFailed, busy, accessNeeded, historyChanged, storageLimitReached

    var errorDescription: String? {
        switch self {
        case .historyUnavailable: String(localized: "Change history could not be saved or recovered. Processing stopped. Changes already made to your contacts are kept.")
        case .contactsChanged: String(localized: "A contact changed while processing. Processing stopped; changes already made are kept.")
        case .saveFailed: String(localized: "A contact could not be saved. Changes already made are recorded in Version History.")
        case .busy: String(localized: "Another contact operation is running. Wait for it to finish.")
        case .accessNeeded: String(localized: "Allow contacts access in Settings to view a restore preview or recover pending changes.")
        case .historyChanged: String(localized: "Version history has changed. Reload the history or restore preview before continuing.")
        case .storageLimitReached: String(localized: "This operation needs more history space than the storage limit allows. Changes already made are kept.")
        }
    }
}

enum ContactOperationOutcome: Sendable, Equatable {
    case completed, stopped, failed(ContactVersionError)
    var succeeded: Bool {
        if case .completed = self {
            return true
        }; return false
    }

    var status: String {
        switch self {
        case .completed: String(localized: "Completed")
        case .stopped: String(localized: "Stopped")
        case .failed: String(localized: "Unable to Update Contacts")
        }
    }
}

enum ContactVersionField: String, Codable, CaseIterable, Sendable {
    case givenName, familyName, phoneticFamilyName, phoneticGivenName, nickname, phoneticMiddleName, note
    case departmentName, organizationName, jobTitle, namePrefix, nameSuffix, socialProfiles, instantMessageAddresses

    var key: String {
        switch self {
        case .givenName: CNContactGivenNameKey
        case .familyName: CNContactFamilyNameKey
        case .phoneticFamilyName: CNContactPhoneticFamilyNameKey
        case .phoneticGivenName: CNContactPhoneticGivenNameKey
        case .nickname: CNContactNicknameKey
        case .phoneticMiddleName: CNContactPhoneticMiddleNameKey
        case .note: CNContactNoteKey
        case .departmentName: CNContactDepartmentNameKey
        case .organizationName: CNContactOrganizationNameKey
        case .jobTitle: CNContactJobTitleKey
        case .namePrefix: CNContactNamePrefixKey
        case .nameSuffix: CNContactNameSuffixKey
        case .socialProfiles: CNContactSocialProfilesKey
        case .instantMessageAddresses: CNContactInstantMessageAddressesKey
        }
    }

    var title: String {
        switch self {
        case .givenName: String(localized: "First Name")
        case .familyName: String(localized: "Last Name")
        case .phoneticFamilyName: String(localized: "Phonetic last name")
        case .phoneticGivenName: String(localized: "Phonetic first name")
        case .nickname: String(localized: "Nickname")
        case .phoneticMiddleName: String(localized: "Phonetic Middle Name")
        case .note: String(localized: "Notes")
        case .departmentName: String(localized: "Department")
        case .organizationName: String(localized: "Company")
        case .jobTitle: String(localized: "Job Title")
        case .namePrefix: String(localized: "Name Prefix")
        case .nameSuffix: String(localized: "Name Suffix")
        case .socialProfiles: String(localized: "Social Profiles")
        case .instantMessageAddresses: String(localized: "Instant Messaging Accounts")
        }
    }

    var isText: Bool {
        self != .socialProfiles && self != .instantMessageAddresses
    }
}

/// Only the field being changed is retained. Array archives preserve CNLabeledValue identifiers.
struct ContactVersionValue: Codable, Sendable, Equatable {
    let text: String?
    let archive: Data?
    let comparison: Data
    let summary: String

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.comparison == rhs.comparison && (lhs.text != nil) == (rhs.text != nil)
    }

    static func read(_ field: ContactVersionField, from contact: CNContact) throws -> Self {
        guard contact.isKeyAvailable(field.key) else { throw ContactVersionError.historyUnavailable }
        if field.isText {
            guard let text = contact.value(forKey: field.key) as? String else { throw ContactVersionError.historyUnavailable }
            return Self(text: text, archive: nil, comparison: Data(text.utf8), summary: text)
        }
        let entries: [[String: String]]
        let summary: String
        switch field {
        case .socialProfiles:
            entries = contact.socialProfiles.map { ["id": $0.identifier, "label": $0.label ?? "", "url": $0.value.urlString, "username": $0.value.username, "userID": $0.value.userIdentifier, "service": $0.value.service] }
            summary = contact.socialProfiles.map {
                [$0.value.service, $0.value.username, $0.value.urlString, $0.value.userIdentifier].filter { !$0.isEmpty }.joined(separator: " · ")
            }.joined(separator: "\n")
        case .instantMessageAddresses:
            entries = contact.instantMessageAddresses.map { ["id": $0.identifier, "label": $0.label ?? "", "username": $0.value.username, "service": $0.value.service] }
            summary = contact.instantMessageAddresses.map {
                [$0.value.service, $0.value.username].filter { !$0.isEmpty }.joined(separator: " · ")
            }.joined(separator: "\n")
        default: throw ContactVersionError.historyUnavailable
        }
        let wrapper = CNMutableContact()
        wrapper.setValue(contact.value(forKey: field.key), forKey: field.key)
        let archive = try NSKeyedArchiver.archivedData(withRootObject: wrapper, requiringSecureCoding: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try Self(text: nil, archive: archive, comparison: encoder.encode(entries), summary: summary)
    }

    func apply(_ field: ContactVersionField, to contact: CNMutableContact) throws {
        if field.isText {
            guard let text, archive == nil, comparison == Data(text.utf8) else { throw ContactVersionError.historyUnavailable }
            contact.setValue(text, forKey: field.key)
        } else {
            guard text == nil, let archive,
                  let wrapper = try NSKeyedUnarchiver.unarchivedObject(ofClass: CNContact.self, from: archive),
                  try Self.read(field, from: wrapper) == self else { throw ContactVersionError.historyUnavailable }
            contact.setValue(wrapper.value(forKey: field.key), forKey: field.key)
        }
    }
}

struct ContactVersionChange: Codable, Sendable, Identifiable {
    let contactID: String
    let contactName: String
    let field: ContactVersionField
    let before: ContactVersionValue
    let after: ContactVersionValue
    var uncertain = false
    var id: String {
        contactID + ":" + field.rawValue
    }
}

enum ContactVersionKind: String, Codable, Sendable {
    case addPinyin, clearFields, editContact, restore
    var title: String {
        switch self {
        case .addPinyin: String(localized: "Add Pinyin")
        case .clearFields: String(localized: "Clear Contact Fields")
        case .editContact: String(localized: "Edit Contact")
        case .restore: String(localized: "Restore Version")
        }
    }
}

struct ContactVersion: Codable, Sendable, Identifiable {
    let id: UUID
    let ordinal: Int
    let createdAt: Date
    let kind: ContactVersionKind
    let targetOrdinal: Int?
    let status: ContactVersionStatus
    let contactCount: Int
    let fieldCount: Int
}

struct ContactVersionHistory: Sendable {
    let versions: [ContactVersion]
    let usedBytes: Int64
    let limitBytes: Int64
    let earliestOrdinal: Int
}

enum ContactVersionStatus: String, Codable, Sendable {
    case pending, completed, stopped, failed, interrupted
    var title: String {
        switch self {
        case .pending: String(localized: "In Progress")
        case .completed: String(localized: "Completed")
        case .stopped: String(localized: "Stopped")
        case .failed: String(localized: "Partially Completed")
        case .interrupted: String(localized: "Interrupted")
        }
    }
}

struct ContactRestoreEntry: Sendable, Identifiable {
    let change: ContactVersionChange
    let current: ContactVersionValue?
    let isConflict: Bool
    var id: String {
        change.id
    }
}

struct ContactRestorePreview: Sendable {
    let headID: UUID?
    let targetOrdinal: Int
    let entries: [ContactRestoreEntry]
}

protocol ContactVersionSource: Sendable {
    func hasAccess() -> Bool
    func read(identifier: String, fields: [ContactVersionField]) throws -> CNContact?
    func save(_ contact: CNMutableContact) throws
}

struct SystemContactVersionSource: ContactVersionSource {
    func hasAccess() -> Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status == .authorized {
            return true
        }
        if #available(iOS 18.0, *), status == .limited {
            return true
        }
        return false
    }

    func read(identifier: String, fields: [ContactVersionField]) throws -> CNContact? {
        guard hasAccess() else { throw ContactVersionError.accessNeeded }
        do {
            let keys = fields.map { $0.key as CNKeyDescriptor } + [CNContactFormatter.descriptorForRequiredKeys(for: .fullName)]
            let contact = try CNContactStore().unifiedContact(withIdentifier: identifier, keysToFetch: keys)
            // A changed linked-contact identity cannot be treated as the original logical record.
            return contact.identifier == identifier ? contact : nil
        } catch let error as NSError where error.domain == CNErrorDomain && error.code == CNError.Code.recordDoesNotExist.rawValue {
            return nil
        }
    }

    func save(_ contact: CNMutableContact) throws {
        let request = CNSaveRequest()
        request.update(contact)
        try CNContactStore().execute(request)
    }
}
