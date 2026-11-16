@testable import Phonetic
import Contacts
import Foundation
import Testing

private enum WhitelistFetchError: Error, Equatable { case failed }

private final class PartialFailureContactStore: CNContactStore {
    override func enumerateContacts(with fetchRequest: CNContactFetchRequest, usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void) throws {
        let contact = CNMutableContact()
        contact.givenName = "Partial"
        var stop: ObjCBool = false
        block(contact, &stop)
        throw WhitelistFetchError.failed
    }
}

struct WhitelistContactTests {
    @Test("A failed enumeration never returns a partial contact list")
    static func partialFetchFailure() async throws {
        let defaults = try #require(UserDefaults(suiteName: "WhitelistFetch.\(UUID().uuidString)"))
        let engine = PhoneticContacts(userDefaults: defaults, contactStore: PartialFailureContactStore())
        await #expect(throws: WhitelistFetchError.failed) {
            _ = try await engine.fetchWhitelistContacts()
        }
    }

    @Test("A cancelled contact fetch does not publish a partial or empty result")
    @MainActor static func cancelledFetch() async throws {
        let defaults = try #require(UserDefaults(suiteName: "WhitelistFetch.\(UUID().uuidString)"))
        let engine = PhoneticContacts(userDefaults: defaults, contactStore: PartialFailureContactStore())
        let task = Task { _ = try await engine.fetchWhitelistContacts() }
        task.cancel()
        await #expect(throws: CancellationError.self) { _ = try await task.value }
    }

    @Test("An overlapping refresh publishes only the latest contact data")
    @MainActor static func overlappingRefreshes() async {
        let coordinator = WhitelistContactRefreshCoordinator()
        let (started, signal) = AsyncStream<Void>.makeStream()
        var resumeOldFetch: CheckedContinuation<Void, Never>?
        var published = "original"

        let first = coordinator.schedule { isLatest in
            await withCheckedContinuation { continuation in
                resumeOldFetch = continuation
                signal.yield(())
            }
            if isLatest() {
                published = "stale"
            }
        }
        // Wait until the earlier refresh is suspended before requesting another one.
        for await _ in started {
            break
        }

        let second = coordinator.schedule { isLatest in
            if isLatest() {
                published = "updated"
            }
        }
        await second.value
        resumeOldFetch?.resume()
        await first.value
        #expect(published == "updated")
    }

    @Test("A cancelled refresh cannot replace visible contacts")
    @MainActor static func cancelledRefreshCannotPublish() async {
        let coordinator = WhitelistContactRefreshCoordinator()
        var didPublish = false
        let task = coordinator.schedule { isLatest in
            await Task.yield()
            if isLatest() {
                didPublish = true
            }
        }
        coordinator.cancel()
        await task.value
        #expect(!didPublish)
    }

    @Test("Limited contact authorization has a distinct empty state")
    static func limitedAccessEmptyState() {
        if #available(iOS 18.0, *) {
            #expect(WhitelistAccessPresentation.showLimitedEmptyState(status: .limited, visibleCount: 0))
            #expect(!WhitelistAccessPresentation.showLimitedEmptyState(status: .limited, visibleCount: 1))
            #expect(!WhitelistAccessPresentation.showLimitedEmptyState(status: .authorized, visibleCount: 0))
            #expect(!WhitelistAccessPresentation.showLimitedEmptyState(status: .denied, visibleCount: 0))
        }
    }

    @Test("full names retain prefix, given name, and family name")
    static func fullNames() throws {
        let contact = CNMutableContact()
        contact.namePrefix = "Dr."
        contact.givenName = "Ada"
        contact.familyName = "Lovelace"
        contact.organizationName = "Fallback Company"
        contact.nickname = "Fallback Nickname"
        let name = contact.whitelistDisplayName
        try #require(name.contains("Dr.") && name.contains("Ada") && name.contains("Lovelace"), "The full name lost a component")
        try #require(!name.contains("Fallback"), "Fallback fields replaced the full name")
    }

    @Test("organization-only contacts have a display name")
    static func organizationNames() throws {
        let contact = CNMutableContact()
        contact.organizationName = "Tesla"
        contact.nickname = "Car service"
        try #require(contact.whitelistDisplayName == "Tesla", "Company should take precedence over nickname; got \(contact.whitelistDisplayName)")
        try #require(contact.matchesWhitelistSearch("TESLA"), "Organization names must be searchable")
    }

    @Test("nickname-only contacts have a display name")
    static func nicknames() throws {
        let contact = CNMutableContact()
        contact.nickname = "  Work  "
        try #require(contact.whitelistDisplayName == "Work", "Nickname fallback was not trimmed")
        try #require(contact.matchesWhitelistSearch("work"), "Nickname fallback must be searchable")
    }

    @Test("phone-only contacts use the first nonempty number")
    static func phoneNumbers() throws {
        let contact = CNMutableContact()
        contact.phoneNumbers = [
            CNLabeledValue(label: CNLabelHome, value: CNPhoneNumber(stringValue: "")),
            CNLabeledValue(label: CNLabelWork, value: CNPhoneNumber(stringValue: "+44 123 456")),
        ]
        contact.emailAddresses = [CNLabeledValue(label: CNLabelWork, value: "ada@example.com" as NSString)]
        try #require(contact.whitelistDisplayName == "+44 123 456", "A phone-only row must identify the contact")
        try #require(contact.matchesWhitelistSearch("123456"), "Phone-number fallback cannot be found")
        try #require(!contact.matchesWhitelistSearch("12"), "Short digit queries should retain the existing three-digit minimum")
    }

    @Test("email-only contacts use the first nonempty address")
    static func emailAddresses() throws {
        let contact = CNMutableContact()
        contact.emailAddresses = [
            CNLabeledValue(label: CNLabelHome, value: " " as NSString),
            CNLabeledValue(label: CNLabelWork, value: " ada@example.com " as NSString),
        ]
        try #require(contact.whitelistDisplayName == "ada@example.com", "An email-only row must identify the contact")
        try #require(contact.matchesWhitelistSearch("EXAMPLE.COM"), "Email matching should ignore case")
    }

    @Test("contacts without identifying fields have a placeholder")
    static func unnamedContacts() throws {
        let contact = CNMutableContact()
        contact.givenName = " "
        contact.familyName = "\n"
        contact.organizationName = " "
        contact.nickname = " "
        try #require(contact.whitelistDisplayName == String(localized: "Unnamed Contact"), "A completely unnamed contact needs a localized placeholder")
    }

    @Test("search includes organization, nickname, and email")
    static func fallbackSearch() throws {
        let contact = CNMutableContact()
        contact.givenName = "Ada"
        contact.familyName = "Lovelace"
        contact.organizationName = "Café Research"
        contact.nickname = "Analyst"
        contact.emailAddresses = [CNLabeledValue(label: CNLabelWork, value: "ada@example.com" as NSString)]
        for query in ["cafe", "ANALYST", "example.com", "  Lovelace Ada  ", "  "] {
            try #require(contact.matchesWhitelistSearch(query), "Search failed for \(query)")
        }
        try #require(!contact.matchesWhitelistSearch("not present"), "Unrelated search unexpectedly matched")
    }

    @Test("existing name, phonetic, and phone searches still work")
    static func existingSearch() throws {
        let contact = CNMutableContact()
        contact.familyName = "叶"
        contact.givenName = "紫萱"
        contact.phoneticFamilyName = "Yè"
        contact.phoneticGivenName = "Zǐxuān"
        contact.phoneNumbers = [CNLabeledValue(label: CNLabelWork, value: CNPhoneNumber(stringValue: "+86 123-456-789"))]
        for query in ["叶紫萱", "紫萱 叶", "ye zixuan", "zixuan ye", "456789"] {
            try #require(contact.matchesWhitelistSearch(query), "Existing search regressed for \(query)")
        }
    }

    @Test("fetch descriptors cover formatting and every fallback field")
    static func fetchContract() throws {
        let suiteName = "Phonetic.WhitelistContactTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = PhoneticContacts(userDefaults: defaults)
        let keys = engine.keysToFetchForWhitelist
        let stringKeys = Set(keys.compactMap { $0 as? String })
        // This is a fetch contract, not just a display check: accessing any of these properties on
        // a store-fetched contact throws an Objective-C exception when the key was not requested.
        let required = [
            CNContactGivenNameKey, CNContactFamilyNameKey, CNContactMiddleNameKey,
            CNContactNamePrefixKey, CNContactNameSuffixKey, CNContactOrganizationNameKey,
            CNContactNicknameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey,
            CNContactPhoneticGivenNameKey, CNContactPhoneticFamilyNameKey,
            CNContactThumbnailImageDataKey, CNContactImageDataAvailableKey,
        ]
        try #require(Set(required).isSubset(of: stringKeys), "Fetch keys do not cover all row, search, and fallback properties")
        let formatterKeys = CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
        try #require(keys.contains { ($0 as? NSObject)?.isEqual(formatterKeys) == true }, "Formatter-required keys are missing")
        defaults.set(false, forKey: kEnableNickname)
        defaults.set(true, forKey: kEnableCustomName)
        let destinations: [(QuickSearch, String)] = [
            (.notes, CNContactNoteKey), (.prefix, CNContactNamePrefixKey),
            (.suffix, CNContactNameSuffixKey), (.middleName, CNContactPhoneticMiddleNameKey),
        ]
        for (selection, key) in destinations {
            defaults.set(selection.rawValue, forKey: kQuickSearchKeyRawValue)
            try #require(engine.keysToFetchForWhitelist.contains { ($0 as? String) == key }, "Configured quick-search key is missing from fetch request")
        }
    }
}
