// Created by Augus on 2/2/16
// Copyright © 2016 Augus <iAugux@gmail.com>

import Foundation

// REFERENCE: http://www.smartisan.com/special/#/duoyinzi

// Some polyphonic characters don't need to be fixed:
// 宓 郇 隗 乐 覃 藏 朝 便 校 行
// 艾 巴 暴 贲 邲 伯 柏 车 冲 褚......

enum PolyphonicChar {
    static let all = [
        b1, b2, b3,
        c1, c2, c3,
        d1,
        g1, g2, g3, g4,
        h1,
        j1, j2,
        k1,
        m1, m2,
        n1,
        o1,
        p1, p2,
        q2, q3, q4, q5,
        r1,
        s1, s2, s3, s4,
        x1, x2,
        y1, y2, y3, y4,
        z1, z2, z3, z4, z5,
    ]

    static let b1 = Polyphonic(character: "秘", replacement: "必", pinyin: "bì")
    static let b2 = Polyphonic(character: "薄", replacement: "博", pinyin: "bó")
    static let b3 = Polyphonic(character: "卜", replacement: "补", pinyin: "bǔ")

    static let c1 = Polyphonic(character: "重", replacement: "虫", pinyin: "chóng")
    static let c2 = Polyphonic(character: "种", replacement: "虫", pinyin: "chóng")
    static let c3 = Polyphonic(character: "单于", replacement: "缠于", pinyin: "chán yú", traditional: "單于")

    static let d1 = Polyphonic(character: "都", replacement: "嘟", pinyin: "dū")

    static let g1 = Polyphonic(character: "盖", replacement: "哿", pinyin: "gě", traditional: "蓋")
    static let g2 = Polyphonic(character: "句", replacement: "勾", pinyin: "gōu")
    static let g3 = Polyphonic(character: "炅", replacement: "贵", pinyin: "guì")
    static let g4 = Polyphonic(character: "过", replacement: "锅", pinyin: "guō", traditional: "過")

    static let h1 = Polyphonic(character: "华", replacement: "话", pinyin: "huà", traditional: "華")

    static let j1 = Polyphonic(character: "纪", replacement: "几", pinyin: "jǐ", traditional: "紀")
    static let j2 = Polyphonic(character: "圈", replacement: "眷", pinyin: "juàn")

    static let k1 = Polyphonic(character: "阚", replacement: "看", pinyin: "kàn", traditional: "闞")

    static let m1 = Polyphonic(character: "缪", replacement: "庙", pinyin: "miào", traditional: "繆")
    static let m2 = Polyphonic(character: "万俟", replacement: "莫奇", pinyin: "mò qí", traditional: "萬俟")

    static let n1 = Polyphonic(character: "粘", replacement: "年", pinyin: "nián")

    static let o1 = Polyphonic(character: "区", replacement: "欧", pinyin: "ōu", traditional: "區")

    static let p1 = Polyphonic(character: "朴", replacement: "嫖", pinyin: "piáo")
    static let p2 = Polyphonic(character: "繁", replacement: "婆", pinyin: "pó")

    static let q2 = Polyphonic(character: "卡", replacement: "酠", pinyin: "qiǎ")
    static let q3 = Polyphonic(character: "乾", replacement: "钱", pinyin: "qián")
    static let q4 = Polyphonic(character: "覃", replacement: "秦", pinyin: "qín")
    static let q5 = Polyphonic(character: "仇", replacement: "球", pinyin: "qiú")

    static let r1 = Polyphonic(character: "任", replacement: "人", pinyin: "rén")

    static let s1 = Polyphonic(character: "单", replacement: "善", pinyin: "shàn", traditional: "單")
    static let s2 = Polyphonic(character: "召", replacement: "绍", pinyin: "shào")
    static let s3 = Polyphonic(character: "折", replacement: "蛇", pinyin: "shé")
    static let s4 = Polyphonic(character: "沈", replacement: "审", pinyin: "shěn")

    static let x1 = Polyphonic(character: "颉", replacement: "鞋", pinyin: "xié", traditional: "頡")
    static let x2 = Polyphonic(character: "解", replacement: "谢", pinyin: "xiè")

    static let y1 = Polyphonic(character: "燕", replacement: "烟", pinyin: "yān")
    static let y2 = Polyphonic(character: "闫", replacement: "颜", pinyin: "yán", traditional: "閆")
    static let y3 = Polyphonic(character: "员", replacement: "运", pinyin: "yùn", traditional: "員")
    static let y4 = Polyphonic(character: "尉迟", replacement: "玉迟", pinyin: "yù chí", preferenceCharacter: "玉迟", traditional: "尉遲")

    static let z1 = Polyphonic(character: "曾", replacement: "增", pinyin: "zēng")
    static let z2 = Polyphonic(character: "查", replacement: "渣", pinyin: "zhā")
    static let z3 = Polyphonic(character: "翟", replacement: "宅", pinyin: "zhái")
    static let z4 = Polyphonic(character: "祭", replacement: "债", pinyin: "zhài")
    static let z5 = Polyphonic(character: "中行", replacement: "中航", pinyin: "zhōng háng")
}

final class Polyphonic: Sendable {
    let character: String
    let spellings: [String]
    let replacement: String
    let pinyin: String
    let key: String

    func displaySpellings(for locale: Locale) -> String {
        guard spellings.count > 1 else { return character }
        if locale.language.maximalIdentifier.hasPrefix("zh-Hant-") {
            return spellings.reversed().joined(separator: "／")
        }
        return spellings.joined(separator: "／")
    }

    func isEnabled(in defaults: UserDefaults) -> Bool {
        guard defaults.object(forKey: key) != nil else { return true }
        return defaults.bool(forKey: key)
    }

    init(character: String, replacement: String, pinyin: String, preferenceCharacter: String? = nil, traditional: String? = nil) {
        self.character = character
        self.spellings = traditional.map { [character, $0] } ?? [character]
        self.replacement = replacement
        self.pinyin = pinyin
        self.key = "kPolyphonicKey+" + (preferenceCharacter ?? character)
    }
}
