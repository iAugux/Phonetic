@testable import Phonetic
import Foundation
import Testing

struct PinyinFormattingTests {
    @Test("Generated name and live example agree across all formatting settings",
          arguments: [false, true], [false, true])
    static func formatting(useTones: Bool, separated: Bool) throws {
        let suite = "PinyinFormatting.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(useTones, forKey: kUseTones)
        defaults.set(separated, forKey: kAlwaysSeparatePinyin)
        let engine = PhoneticContacts(userDefaults: defaults)
        for upcase in [false, true] {
            defaults.set(upcase, forKey: kUpcasePinyin)
            let family = try #require(engine.phonetic("林", needFix: false))
            let given = try #require(engine.phonetic("沐晴", needFix: false))
            let expected: String
            if useTones {
                expected = separated ? "Mù Qíng" : (upcase ? "MùQíng" : "Mùqíng")
            } else {
                expected = separated ? "Mu Qing" : (upcase ? "MuQing" : "Muqing")
            }
            #expect(given.value == expected)
            #expect(family.value == (useTones ? "Lín" : "Lin"))
            #expect(given.brief == "MQ" && family.brief == "L")
            #expect(Phonetic.exampleName(useTones: useTones, separated: separated, upcase: upcase) == "\(family.value) \(given.value)")
        }
    }

    @Test("Separated repeated syllables have no leading or trailing whitespace")
    static func repeatedSyllables() throws {
        let suite = "PinyinFormatting.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: kAlwaysSeparatePinyin)
        defaults.set(false, forKey: kUseTones)
        let engine = PhoneticContacts(userDefaults: defaults)
        let value = try #require(engine.phonetic("婷婷", needFix: false))
        #expect(value.value == "Ting Ting")
        #expect(value.brief == "TT")
        #expect(Phonetic.joinSyllables(["", "ting", "", "ting", ""], separated: true, upcase: false) == "Ting Ting")
    }
}
