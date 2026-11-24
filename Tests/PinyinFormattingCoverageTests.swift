@testable import Phonetic
import Foundation
import Testing

private final class PinyinFixture {
    private let suite = "PinyinCoverage.\(UUID().uuidString)"
    let defaults: UserDefaults
    let engine: PhoneticContacts

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suite))
        engine = PhoneticContacts(userDefaults: defaults)
    }

    deinit { defaults.removePersistentDomain(forName: suite) }
}

struct PinyinFormattingCoverageTests {
    @Test("Unset preferences produce the same default name as the example")
    static func defaultPreferences() throws {
        let fixture = try PinyinFixture()
        for key in [kUseTones, kUpcasePinyin, kAlwaysSeparatePinyin] {
            #expect(fixture.defaults.object(forKey: key) == nil)
        }
        let family = try #require(fixture.engine.phonetic("林", needFix: false))
        let given = try #require(fixture.engine.phonetic("沐晴", needFix: false))
        #expect("\(family.value) \(given.value)" == "Lin Muqing")
        #expect(Phonetic.exampleName(useTones: kUseTonesDefaultBool,
                                     separated: kAlwaysSeparatePinyinDefaultBool,
                                     upcase: kUpcasePinyinDefaultBool) == "Lin Muqing")
    }

    @Test("An existing engine follows preference changes without recreating it")
    static func preferenceChanges() throws {
        let fixture = try PinyinFixture()
        let cases: [(tones: Bool, separated: Bool, upcase: Bool, expected: String)] = [
            (true, true, false, "Lín Mù Qíng"),
            (true, false, false, "Lín Mùqíng"),
            (true, false, true, "Lín MùQíng"),
            (false, false, true, "Lin MuQing"),
            (false, false, false, "Lin Muqing"),
            (false, true, false, "Lin Mu Qing"),
            (true, true, false, "Lín Mù Qíng"),
        ]
        for item in cases {
            fixture.defaults.set(item.tones, forKey: kUseTones)
            fixture.defaults.set(item.separated, forKey: kAlwaysSeparatePinyin)
            fixture.defaults.set(item.upcase, forKey: kUpcasePinyin)
            let family = try #require(fixture.engine.phonetic("林", needFix: false))
            let given = try #require(fixture.engine.phonetic("沐晴", needFix: false))
            #expect(item.expected == "\(family.value) \(given.value)")
            #expect(Phonetic.exampleName(useTones: item.tones, separated: item.separated, upcase: item.upcase) == item.expected)
        }
    }

    @Test("Tone marks on initial vowels never leak into quick-search initials",
          arguments: [false, true], [false, true])
    static func accentedInitials(useTones: Bool, separated: Bool) throws {
        let fixture = try PinyinFixture()
        fixture.defaults.set(useTones, forKey: kUseTones)
        fixture.defaults.set(separated, forKey: kAlwaysSeparatePinyin)
        for upcase in [false, true] {
            fixture.defaults.set(upcase, forKey: kUpcasePinyin)
            let result = try #require(fixture.engine.phonetic("欧阳", needFix: false))
            let expected: String = if useTones {
                separated ? "Ōu Yáng" : (upcase ? "ŌuYáng" : "Ōuyáng")
            } else {
                separated ? "Ou Yang" : (upcase ? "OuYang" : "Ouyang")
            }
            #expect(result.value == expected)
            #expect(result.brief == "OY")
        }
    }

    @Test("Extra spaces in Chinese names cannot create edge or repeated output spaces",
          arguments: [false, true], [false, true])
    static func inputWhitespace(useTones: Bool, separated: Bool) throws {
        let fixture = try PinyinFixture()
        fixture.defaults.set(useTones, forKey: kUseTones)
        fixture.defaults.set(separated, forKey: kAlwaysSeparatePinyin)
        for upcase in [false, true] {
            fixture.defaults.set(upcase, forKey: kUpcasePinyin)
            for input in ["  沐晴  ", "沐  晴"] {
                let result = try #require(fixture.engine.phonetic(input, needFix: false))
                let expected: String = if useTones {
                    separated ? "Mù Qíng" : (upcase ? "MùQíng" : "Mùqíng")
                } else {
                    separated ? "Mu Qing" : (upcase ? "MuQing" : "Muqing")
                }
                #expect(result.value == expected)
                #expect(result.brief == "MQ")
            }
        }
    }

    @Test("A mixed Han and Latin name still generates pinyin", arguments: [false, true])
    static func mixedName(useTones: Bool) throws {
        let fixture = try PinyinFixture()
        fixture.defaults.set(useTones, forKey: kUseTones)
        fixture.defaults.set(true, forKey: kAlwaysSeparatePinyin)
        let result = try #require(fixture.engine.phonetic("林 Ada", needFix: false))
        #expect(result.value == (useTones ? "Lín Ada" : "Lin Ada"))
        #expect(result.brief == "LA")
    }

    @Test("Non-Chinese and empty names remain unchanged rather than generating phonetic values",
          arguments: ["", "Ada", "Ada Lovelace", "José", "Renée", "Jose\u{301}", "1234"], [false, true])
    static func unchangedNames(input: String, useTones: Bool) throws {
        let fixture = try PinyinFixture()
        fixture.defaults.set(useTones, forKey: kUseTones)
        fixture.defaults.set(true, forKey: kAlwaysSeparatePinyin)
        fixture.defaults.set(true, forKey: kUpcasePinyin)
        #expect(fixture.engine.phonetic(input, needFix: false) == nil)
    }
}
