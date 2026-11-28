@testable import Phonetic
import Foundation
import Testing

struct PolyphonicCharacterTests {
    @Test("Every polyphonic override replacement produces its expected tone-marked pinyin")
    static func replacementPinyinAndTones() throws {
        let expected: [(character: String, replacement: String, pinyin: String)] = [
            ("秘", "必", "bì"),
            ("薄", "博", "bó"),
            ("卜", "补", "bǔ"),
            ("重", "虫", "chóng"),
            ("种", "虫", "chóng"),
            ("单于", "缠于", "chán yú"),
            ("都", "嘟", "dū"),
            ("盖", "哿", "gě"),
            ("句", "勾", "gōu"),
            ("炅", "贵", "guì"),
            ("过", "锅", "guō"),
            ("华", "话", "huà"),
            ("纪", "几", "jǐ"),
            ("圈", "眷", "juàn"),
            ("阚", "看", "kàn"),
            ("缪", "庙", "miào"),
            ("万俟", "莫奇", "mò qí"),
            ("粘", "年", "nián"),
            ("区", "欧", "ōu"),
            ("朴", "嫖", "piáo"),
            ("繁", "婆", "pó"),
            ("卡", "酠", "qiǎ"),
            ("乾", "钱", "qián"),
            ("覃", "秦", "qín"),
            ("仇", "球", "qiú"),
            ("任", "人", "rén"),
            ("单", "善", "shàn"),
            ("召", "绍", "shào"),
            ("折", "蛇", "shé"),
            ("沈", "审", "shěn"),
            ("颉", "鞋", "xié"),
            ("解", "谢", "xiè"),
            ("燕", "烟", "yān"),
            ("闫", "颜", "yán"),
            ("员", "运", "yùn"),
            ("尉迟", "玉迟", "yù chí"),
            ("曾", "增", "zēng"),
            ("查", "渣", "zhā"),
            ("翟", "宅", "zhái"),
            ("祭", "债", "zhài"),
            ("中行", "中航", "zhōng háng"),
        ]

        // Keep expected entries independent from the production pinyin values.
        #expect(PolyphonicChar.all.map(\.character).sorted() == expected.map(\.character).sorted())

        let suiteName = "PolyphonicCharacterTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: kUseTones)
        defaults.set(true, forKey: kAlwaysSeparatePinyin)
        defaults.set(false, forKey: kUpcasePinyin)
        let engine = PhoneticContacts(userDefaults: defaults)

        for fixture in expected {
            let override = try #require(PolyphonicChar.all.first { $0.character == fixture.character })
            #expect(override.replacement == fixture.replacement)
            #expect(override.pinyin == fixture.pinyin)
            #expect(engine.manaullyFixPolyphonicCharacters(fixture.character) == fixture.replacement)

            // Exercise the same override-enabled path used for contact family names.
            let result = try #require(engine.phonetic(fixture.character, needFix: true))
            #expect(result.value.lowercased() == fixture.pinyin)
        }
    }

    @Test("戚 keeps its first tone and 尉迟 honors the existing surname preference")
    static func qiAndYuchi() throws {
        let suiteName = "QiAndYuchi.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: kUseTones)
        defaults.set(true, forKey: kAlwaysSeparatePinyin)
        let engine = PhoneticContacts(userDefaults: defaults)

        #expect(engine.phonetic("戚", needFix: true)?.value == "Qī")
        #expect(engine.phonetic("尉迟", needFix: true)?.value == "Yù Chí")
        defaults.set(false, forKey: "kPolyphonicKey+玉迟")
        #expect(engine.manaullyFixPolyphonicCharacters("尉迟") == "尉迟")
    }

    @Test("Enabling the 种 correction preserves the system reading and initial for 種")
    static func distinctZhongSurname() throws {
        let suiteName = "DistinctZhongSurname.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: kUseTones)
        defaults.set(true, forKey: PolyphonicChar.c2.key)
        let engine = PhoneticContacts(userDefaults: defaults)

        let corrected = try #require(engine.phonetic("种", needFix: true))
        #expect(corrected.value.lowercased() == "chóng")
        #expect(corrected.brief == "C")

        #expect(engine.manaullyFixPolyphonicCharacters("種") == "種")
        let system = try #require(engine.phonetic("種", needFix: false))
        let result = try #require(engine.phonetic("種", needFix: true))
        #expect(result.value == system.value)
        #expect(result.brief == system.brief)
    }

    @Test("Surname labels order the configured spellings for the interface locale")
    static func localizedSurnameLabels() {
        for identifier in ["zh-Hans", "zh-CN", "zh-Hans-TW", "en-TW"] {
            let locale = Locale(identifier: identifier)
            #expect(PolyphonicChar.o1.displaySpellings(for: locale) == "区／區")
            #expect(PolyphonicChar.c3.displaySpellings(for: locale) == "单于／單于")
            #expect(PolyphonicChar.c2.displaySpellings(for: locale) == "种")
        }
        for identifier in ["zh-Hant", "zh-TW", "zh-HK", "zh-Hant-CN"] {
            let locale = Locale(identifier: identifier)
            #expect(PolyphonicChar.o1.displaySpellings(for: locale) == "區／区")
            #expect(PolyphonicChar.c3.displaySpellings(for: locale) == "單于／单于")
            #expect(PolyphonicChar.c2.displaySpellings(for: locale) == "种")
        }
    }

    @Test("Traditional surname spellings share the simplified rule and its preference")
    static func traditionalSpellings() throws {
        let suiteName = "TraditionalSurnames.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: kUseTones)
        defaults.set(true, forKey: kAlwaysSeparatePinyin)
        let engine = PhoneticContacts(userDefaults: defaults)
        let pairs = [
            ("单于", "單于"), ("盖", "蓋"), ("过", "過"), ("华", "華"),
            ("纪", "紀"), ("阚", "闞"), ("缪", "繆"), ("万俟", "萬俟"), ("区", "區"),
            ("单", "單"), ("颉", "頡"), ("闫", "閆"), ("员", "員"), ("尉迟", "尉遲"),
        ]

        // Isolate each rule while checking aliases and their shared preference.
        for rule in PolyphonicChar.all {
            defaults.set(false, forKey: rule.key)
        }
        for (simplified, traditional) in pairs {
            let rule = try #require(PolyphonicChar.all.first { $0.character == simplified })
            #expect(engine.manaullyFixPolyphonicCharacters(traditional) == traditional)
            defaults.set(true, forKey: rule.key)
            #expect(engine.manaullyFixPolyphonicCharacters(traditional) == rule.replacement)
            let result = try #require(engine.phonetic(traditional, needFix: true))
            #expect(result.value.lowercased() == rule.pinyin)
            defaults.set(false, forKey: rule.key)
        }
    }

    @Test("Compound surnames respect their own switch when the single-character rule is on", arguments: ["单于", "單于"])
    static func compoundSurnameSwitch(surname: String) throws {
        let suiteName = "CompoundSurnameSwitch.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: kUseTones)
        defaults.set(true, forKey: kAlwaysSeparatePinyin)
        defaults.set(true, forKey: PolyphonicChar.s1.key)
        defaults.set(false, forKey: PolyphonicChar.c3.key)
        let engine = PhoneticContacts(userDefaults: defaults)

        let system = try #require(engine.phonetic(surname, needFix: false))
        let disabled = try #require(engine.phonetic(surname, needFix: true))
        #expect(disabled.value == system.value)
        #expect(disabled.brief == system.brief)
        #expect(engine.manaullyFixPolyphonicCharacters(" \(surname) ") == " \(surname) ")
        #expect(engine.manaullyFixPolyphonicCharacters("\(surname)明") == "\(surname)明")
        #expect(engine.manaullyFixPolyphonicCharacters("\(surname)-\(surname.prefix(1))") == "\(surname)-善")
        #expect(engine.manaullyFixPolyphonicCharacters(String(surname.prefix(1))) == "善")

        defaults.set(true, forKey: PolyphonicChar.c3.key)
        let enabled = try #require(engine.phonetic(surname, needFix: true))
        #expect(enabled.value == "Chán Yú")
        #expect(enabled.brief == "CY")
        #expect(engine.manaullyFixPolyphonicCharacters(" \(surname) ") == " 缠于 ")
        #expect(engine.manaullyFixPolyphonicCharacters("\(surname)明") == "缠于明")
    }

    @Test("Polyphonic overrides respect per-character preferences in the same UserDefaults suite")
    static func disabledAndEnabledOverrides() throws {
        let suiteName = "PolyphonicCharacterPreferences.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = PhoneticContacts(userDefaults: defaults)

        // Disable every override first to avoid overlapping rules, such as 单于 and 单.
        for entry in PolyphonicChar.all {
            defaults.set(false, forKey: entry.key)
        }

        for entry in PolyphonicChar.all {
            #expect(!entry.isEnabled(in: defaults))
            #expect(engine.manaullyFixPolyphonicCharacters(entry.character) == entry.character)

            let unchanged = try #require(engine.phonetic(entry.character, needFix: false))
            let disabled = try #require(engine.phonetic(entry.character, needFix: true))
            #expect(disabled.value == unchanged.value)
            #expect(disabled.brief == unchanged.brief)

            defaults.set(true, forKey: entry.key)
            #expect(entry.isEnabled(in: defaults))
            #expect(engine.manaullyFixPolyphonicCharacters(entry.character) == entry.replacement)

            let replacement = try #require(engine.phonetic(entry.replacement, needFix: false))
            let enabled = try #require(engine.phonetic(entry.character, needFix: true))
            #expect(enabled.value == replacement.value)
            #expect(enabled.brief == replacement.brief)

            defaults.set(false, forKey: entry.key)
        }
    }
}
