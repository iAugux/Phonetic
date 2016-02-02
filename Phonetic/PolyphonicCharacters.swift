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
    static let SpecialCharacters = ["曾", "沈", "单", "仇", "秘", "解", "折", "朴", "翟", "查", "盖", "万俟", "尉迟"]
    static let NewCharacters     = ["增", "审", "善", "球", "必", "谢", "蛇", "嫖", "宅", "渣", "哿", "莫奇", "玉迟"]
}