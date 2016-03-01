//
//  PolyphonicCharacters.swift
//  Phonetic
//
//  Created by Augus on 2/2/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation


/// Add following code to Xcode Playground and replace "重" with your new polyphonic character
/// to test whether the result is completely correct.
/// Note: guarantee the Pinyin Tone is also correct.

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


struct PolyphonicChar {
    
    static let all = [
        b1, b2, b3,
        c1, c2, c3,
        d1,
        g1, g2,
        h1,
        j1,
        k1,
        m1, m2,
        o1,
        p1, p2,
        q1, q2, q3,
        r1,
        s1, s2, s3,
        x1,
        y1, y2, y3, y4,
        z1, z2, z3, z4, z5
    ]
    
    static var b1 = Polyphonic(character: "秘", replacement: "必", pinyin: "bì")
    static var b2 = Polyphonic(character: "薄", replacement: "博", pinyin: "bó")
    static var b3 = Polyphonic(character: "卜", replacement: "补", pinyin: "bǔ")
    
    static var c1 = Polyphonic(character: "重", replacement: "虫", pinyin: "chóng")
    static var c2 = Polyphonic(character: "种", replacement: "虫", pinyin: "chóng")
    static var c3 = Polyphonic(character: "单于", replacement: "缠于", pinyin: "chán yú")
    
    static var d1 = Polyphonic(character: "都", replacement: "嘟", pinyin: "dū")
    
    static var g1 = Polyphonic(character: "盖", replacement: "哿", pinyin: "gě")
    static var g2 = Polyphonic(character: "过", replacement: "锅", pinyin: "guō")
    
    static var h1 = Polyphonic(character: "华", replacement: "话", pinyin: "huà")
    
    static var j1 = Polyphonic(character: "纪", replacement: "几", pinyin: "jǐ")
    
    static var k1 = Polyphonic(character: "阚", replacement: "看", pinyin: "kàn")
    
    static var m1 = Polyphonic(character: "缪", replacement: "庙", pinyin: "miào")
    static var m2 = Polyphonic(character: "万俟", replacement: "莫奇", pinyin: "mò qí")
    
    static var o1 = Polyphonic(character: "区", replacement: "欧", pinyin: "ōu")
    
    static var p1 = Polyphonic(character: "繁", replacement: "婆", pinyin: "pó")
    static var p2 = Polyphonic(character: "朴", replacement: "嫖", pinyin: "piáo")
    
    static var q1 = Polyphonic(character: "覃", replacement: "秦", pinyin: "qín")
    static var q2 = Polyphonic(character: "仇", replacement: "球", pinyin: "qiú")
    static var q3 = Polyphonic(character: "戚", replacement: "器", pinyin: "qì")
    
    static var r1 = Polyphonic(character: "任", replacement: "人", pinyin: "rén")
    
    static var s1 = Polyphonic(character: "单", replacement: "善", pinyin: "shàn")
    static var s2 = Polyphonic(character: "沈", replacement: "审", pinyin: "shěn")
    static var s3 = Polyphonic(character: "折", replacement: "蛇", pinyin: "shé")
    
    static var x1 = Polyphonic(character: "解", replacement: "谢", pinyin: "xiè")
    
    static var y1 = Polyphonic(character: "燕", replacement: "烟", pinyin: "yān")
    static var y2 = Polyphonic(character: "闫", replacement: "颜", pinyin: "yán")
    static var y3 = Polyphonic(character: "员", replacement: "运", pinyin: "yùn")
    static var y4 = Polyphonic(character: "玉迟", replacement: "玉迟", pinyin: "yù chí")
    
    static var z1 = Polyphonic(character: "查", replacement: "渣", pinyin: "zhā")
    static var z2 = Polyphonic(character: "翟", replacement: "宅", pinyin: "zhái")
    static var z3 = Polyphonic(character: "祭", replacement: "债", pinyin: "zhài")
    static var z4 = Polyphonic(character: "曾", replacement: "增", pinyin: "zēng")
    static var z5 = Polyphonic(character: "中行", replacement: "中航", pinyin: "zhōng háng")
    
}

class Polyphonic {
    var character: String
    var replacement: String
    var pinyin: String
    var prefix: String
    var key: String
    
    var on: Bool {
        get {
            guard NSUserDefaults.standardUserDefaults().valueForKey(key) != nil else { return true }
            return NSUserDefaults.standardUserDefaults().boolForKey(key)
        }
    }
    
    init(character: String, replacement: String, pinyin: String) {
        self.character = character
        self.replacement = replacement
        self.pinyin = pinyin
        self.key = "kPolyphonicKey+" + character
        self.prefix = prefixLetter(pinyin)
    }
    
}

private func prefixLetter(str: String) -> String {
    let str = str as NSString
    
    return str.length > 0 ? str.substringToIndex(1).uppercaseString : ""
}
