//
//  PhoneticContacts+Extension.swift
//  Phonetic
//
//  Created by Augus on 2/6/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation
import Contacts

extension PhoneticContacts {
    
    /**
     *  Search name by enter `WXD` (not case-sensitive), then following names will be listed by example.
     *  "王晓东"、"万孝德" ...
     */
    func addNickNameIfNeeded(mutableContact: CNMutableContact, familyBrief: String, givenBrief: String) {
        if let _ = mutableContact.valueForKey(CNContactNicknameKey) as? String {
            mutableContact.setValue(familyBrief + givenBrief, forKey: CNContactNicknameKey)
        }
    }
    
}

