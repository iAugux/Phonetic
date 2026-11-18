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
            ("戚", "器", "qì"),
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
            ("玉迟", "玉迟", "yù chí"),
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
            #expect(engine.manaullyFixPolyphonicCharacters(fixture.character, isEnabled: { _ in true }) == fixture.replacement)

            let result = try #require(engine.phonetic(fixture.replacement, needFix: false))
            #expect(result.value.lowercased() == fixture.pinyin)
        }
    }
}
