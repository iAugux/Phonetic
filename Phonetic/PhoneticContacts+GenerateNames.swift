//
//  PhoneticContacts+GenerateNames.swift
//  Phonetic
//
//  Created by Augus on 2/2/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation
import Contacts


// MARK: - Insert random new contacts for simulator testing.
extension PhoneticContacts {
    
    func insertNewContactsForSimulatorIfNeed(numberOfContacts: Int) {
        #if DEBUG
            
            guard needInsertNewContactsForTesting else { return }
            
            let alertController = InfoAlertController()
            let info = "We will generate some new random contacts for your iOS Simulator to test first."
            alertController.alert(info)
            
            for _ in 0..<numberOfContacts {
                
                let mutableContact = CNMutableContact()
                
                mutableContact.familyName = generateRandomFamilyName()
                mutableContact.givenName  = generateRandomGivenName()
                
                addNewContact(mutableContact)
            }
            
        #endif
    }
    
    func removeAllContactsOfSimulator() {
        #if DEBUG
            
            guard Device.type() == .Simulator else { return }
            
            let keysToFetch = [CNContactFamilyNameKey, CNContactGivenNameKey, CNContactMiddleNameKey]
            
            do {
                try self.contactStore.enumerateContactsWithFetchRequest(CNContactFetchRequest(keysToFetch: keysToFetch), usingBlock: { (contact, _) -> Void in
                    
                    let mutableContact = contact.mutableCopy() as! CNMutableContact
                    
                    if !contact.familyName.isEmpty || !contact.givenName.isEmpty || !contact.middleName.isEmpty {
                        self.deleteContact(mutableContact)
                    }
                })
                
            } catch {
                #if DEBUG
                    NSLog("\(error)")
                #endif
            }
            
            let alertController = InfoAlertController()
            let info = "Removed all contacts of your iOS Simulator!"
            alertController.alert(info)
            
        #endif
    }
    
    private var needInsertNewContactsForTesting: Bool {
        // just insert new contacts for simulator
        guard Device.type() == .Simulator else { return false }
        
        // if there is more enough to test, return false
        guard contactsTotalCount() < 30 else { return false }
        
        return true
    }
    
    private func deleteContact(contact: CNMutableContact) {
        let saveRequest = CNSaveRequest()
        saveRequest.deleteContact(contact)
        do {
            try self.contactStore.executeSaveRequest(saveRequest)
        } catch {
            #if DEBUG
                NSLog("delete contact failed ! - \(error)")
            #endif
        }
    }
    
    private func addNewContact(contact: CNMutableContact) {
        let saveRequest = CNSaveRequest()
        saveRequest.addContact(contact, toContainerWithIdentifier: nil)
        do {
            try self.contactStore.executeSaveRequest(saveRequest)
        } catch {
            #if DEBUG
                NSLog("saving Contact failed ! - \(error)")
            #endif
        }
    }
    
    private func generateRandomFamilyName() -> String {
        let familyNames = ["赵", "钱", "孙", "李", "周", "吴", "郑", "王", "冯", "陈", "褚", "卫", "蒋", "沈", "韩", "杨", "吕", "曹", "沈", "单", "仇", "秘", "解", "折", "朴", "翟", "查", "盖", "万俟", "尉迟"]
        
        let index = Int(arc4random_uniform(UInt32(familyNames.count)))
        return familyNames[index]
    }
    
    private func generateRandomGivenName() -> String {
        let givenNames = ["顺权", "恋萱", "丹凤", "凤铜", "绘葶", "清", "欣爱", "正烨", "恒", "芷涵", "金", "秋雁", "芸", "渲" ,"玟宣", "雨杰", "卓阳", "立", "煜沁", "泽世", "国龙", "鸢", "正兰", "广智", "美慧", "恺", "熙博", "珂"]
        
        let index = Int(arc4random_uniform(UInt32(givenNames.count)))
        return givenNames[index]
    }
    
    
}