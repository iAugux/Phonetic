//
//  PolyphonicCharacters.swift
//  Phonetic
//
//  Created by Augus on 2/2/16.
//  Copyright © 2016 iAugus. All rights reserved.
//



/**
*  Just add new polyphonic character to the array of `SpecialCharacters`,
*  Then add a new character which used replacing the polyphonic character to the array of `NewCharacters`
*
*  Note:
*    1. guarantee the correct Pinyin phonetic.
*    2. guarantee the same index.
*/

struct PolyphonicCharacters {
    static let SpecialCharacters = ["覃", "繁", "缪", "种", "燕", "任", "阚", "纪", "过", "华", "区", "重", "曾", "沈", "单", "仇", "秘", "解", "折", "朴", "翟", "查", "盖", "万俟", "尉迟"]
    
    static let NewCharacters     = ["秦", "婆", "庙", "虫", "烟", "人", "看", "几", "锅", "话", "欧", "虫", "增", "审", "善", "球", "必", "谢", "蛇", "嫖", "宅", "渣", "哿", "莫奇", "玉迟"]
}



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