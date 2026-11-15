// Created by Augus on 2/2/16
// Copyright © 2016 Augus <iAugux@gmail.com>

import Foundation

// Add following code to Xcode Playground and replace "重" with your new polyphonic character
// to test whether the result is completely correct.
// Note: guarantee the Pinyin Tone is also correct.

/*

 import Foundation

 let characterForTesting = "重"

 func phonetic(str: String) -> String? {

 var source = str.mutableCopy()

 CFStringTransform(source as! CFMutableStringRef, nil, kCFStringTransformMandarinLatin, false)

 if !(source as! NSString).isEqualToString(str) {
 if source.rangeOfString(" ").location != NSNotFound {
 let phoneticParts = source.componentsSeparatedByString(" ")

 source = NSMutableString()

 for part in phoneticParts {
 source.appendString(part)
 }
 }
 return source as? String
 }
 return nil
 }

 phonetic(characterForTesting)

 */

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
        q1, q2, q3, q4, q5,
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
    static let c3 = Polyphonic(character: "单于", replacement: "缠于", pinyin: "chán yú")

    static let d1 = Polyphonic(character: "都", replacement: "嘟", pinyin: "dū")

    static let g1 = Polyphonic(character: "盖", replacement: "哿", pinyin: "gě")
    static let g2 = Polyphonic(character: "句", replacement: "勾", pinyin: "gōu")
    static let g3 = Polyphonic(character: "炅", replacement: "贵", pinyin: "guì")
    static let g4 = Polyphonic(character: "过", replacement: "锅", pinyin: "guō")

    static let h1 = Polyphonic(character: "华", replacement: "话", pinyin: "huà")

    static let j1 = Polyphonic(character: "纪", replacement: "几", pinyin: "jǐ")
    static let j2 = Polyphonic(character: "圈", replacement: "眷", pinyin: "juàn")

    static let k1 = Polyphonic(character: "阚", replacement: "看", pinyin: "kàn")

    static let m1 = Polyphonic(character: "缪", replacement: "庙", pinyin: "miào")
    static let m2 = Polyphonic(character: "万俟", replacement: "莫奇", pinyin: "mò qí")

    static let n1 = Polyphonic(character: "粘", replacement: "年", pinyin: "nián")

    static let o1 = Polyphonic(character: "区", replacement: "欧", pinyin: "ōu")

    static let p1 = Polyphonic(character: "朴", replacement: "嫖", pinyin: "piáo")
    static let p2 = Polyphonic(character: "繁", replacement: "婆", pinyin: "pó")

    static let q1 = Polyphonic(character: "戚", replacement: "器", pinyin: "qì")
    static let q2 = Polyphonic(character: "卡", replacement: "酠", pinyin: "qiǎ")
    static let q3 = Polyphonic(character: "乾", replacement: "钱", pinyin: "qián")
    static let q4 = Polyphonic(character: "覃", replacement: "秦", pinyin: "qín")
    static let q5 = Polyphonic(character: "仇", replacement: "球", pinyin: "qiú")

    static let r1 = Polyphonic(character: "任", replacement: "人", pinyin: "rén")

    static let s1 = Polyphonic(character: "单", replacement: "善", pinyin: "shàn")
    static let s2 = Polyphonic(character: "召", replacement: "绍", pinyin: "shào")
    static let s3 = Polyphonic(character: "折", replacement: "蛇", pinyin: "shé")
    static let s4 = Polyphonic(character: "沈", replacement: "审", pinyin: "shěn")

    static let x1 = Polyphonic(character: "颉", replacement: "鞋", pinyin: "xié")
    static let x2 = Polyphonic(character: "解", replacement: "谢", pinyin: "xiè")

    static let y1 = Polyphonic(character: "燕", replacement: "烟", pinyin: "yān")
    static let y2 = Polyphonic(character: "闫", replacement: "颜", pinyin: "yán")
    static let y3 = Polyphonic(character: "员", replacement: "运", pinyin: "yùn")
    static let y4 = Polyphonic(character: "玉迟", replacement: "玉迟", pinyin: "yù chí")

    static let z1 = Polyphonic(character: "曾", replacement: "增", pinyin: "zēng")
    static let z2 = Polyphonic(character: "查", replacement: "渣", pinyin: "zhā")
    static let z3 = Polyphonic(character: "翟", replacement: "宅", pinyin: "zhái")
    static let z4 = Polyphonic(character: "祭", replacement: "债", pinyin: "zhài")
    static let z5 = Polyphonic(character: "中行", replacement: "中航", pinyin: "zhōng háng")
}

final class Polyphonic: Sendable {
    let character: String
    let replacement: String
    let pinyin: String
    let key: String

    var on: Bool {
        guard UserDefaults.standard.value(forKey: key) != nil else { return true }
        return UserDefaults.standard.bool(forKey: key)
    }

    init(character: String, replacement: String, pinyin: String) {
        self.character = character
        self.replacement = replacement
        self.pinyin = pinyin
        self.key = "kPolyphonicKey+" + character
    }
}
