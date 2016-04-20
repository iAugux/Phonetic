//
//  ContactsGenerator.swift
//  Phonetic
//
//  Created by Augus on 2/2/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation
import Contacts
import Device

/**
 For safety, all of these functions will not work on Release Edition. If you do want to, please set `WORK_ON_RELEASE` to true.
 
 Be careful with your Contacts on device. And use on your own risk.
 */
 
 // MARK: - Insert new random contacts for simulator testing.
extension PhoneticContacts {
    
    private var WORK_ON_RELEASE: Bool { return false }
    
    private var DEBUG: Bool {
        
        #if DEBUG
            return true
        #else
            return WORK_ON_RELEASE
        #endif
    }
    
    // MARK: - Insert new contacts
    
    /**
    While there are less than 30 contacts on simulator, it will automatically generate new contacts.
    
    - parameter numberOfContacts: Number of contacts you want to generate.
    */
    func insertNewContactsForSimulatorIfNeeded(numberOfContacts: UInt16) {
        
        guard DEBUG else { return }
        
        guard numberOfContacts != 0 else { return }
        guard needInsertNewContactsForTesting else { return }
        
        insertNewContacts(numberOfContacts)
    }
    
    /**
     Generate new random contacts for simulstor.
     
     - parameter numberOfContacts: Number of contacts you want to generate.
     */
    func insertNewContactsForSimulator(numberOfContacts: UInt16) {
        
        guard DEBUG else { return }
        
        guard numberOfContacts != 0 else { return }
        
        insertNewContacts(numberOfContacts)
    }
    
    /**
     Generate new random contacts for Real Device.
     Be careful with this, I bet you do not want to mess your important contacts on your device.
     
     - parameter numberOfContacts: Number of contacts you want to generate.
     */
    func insertNewContactsForDevice(numberOfContacts: UInt16) {
        
        guard DEBUG else { return }
        
        guard Device.type() != .Simulator else { return }
        guard numberOfContacts != 0 else { return }
        
        insertNewContactsWithMultiAlert(numberOfContacts)
    }
    
    
    // MARK: - Remove all contacts
    func removeAllContactsOfSimulator() {
        
        guard DEBUG else { return }
        
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
            DEBUGLog("\(error)")
        }
        
        let info = "Removed all contacts of your iOS Simulator!"
        AlertController.alert(title: info, completionHandler: nil)
    }
    
    private func insertNewContacts(numberOfContacts: UInt16) {
        
        let info = "We will generate \(numberOfContacts) new random contacts for your iOS Simulator."
        AlertController.alert(title: info) { () -> Void in
            self.generateAndInsert(numberOfContacts)
        }
    }
    
    private func insertNewContactsWithMultiAlert(numberOfContacts: UInt16) {
        let firstInfo = "We will generate \(numberOfContacts) new random contacts for your Device!"
        let secondInfo = "Are you absolutely sure to do this, this will mess your contacts on your device!!!"
        let thirdInfo = "Use on your own risk."
        let multiItemsOfInfo = [firstInfo, secondInfo, thirdInfo]
        AlertController.multiAlertsWithOptions(multiItemsOfInfo) { () -> Void in
            self.generateAndInsert(numberOfContacts)
        }
    }
    
    private func generateAndInsert(numberOfContacts: UInt16) {
        for _ in 0..<numberOfContacts {
            
            let mutableContact = CNMutableContact()
            
            mutableContact.familyName = self.generateRandomFamilyName()
            mutableContact.givenName  = self.generateRandomGivenName()
            
            self.addNewContact(mutableContact)
        }
    }
    
    private var needInsertNewContactsForTesting: Bool {
        // just insert new contacts for simulator
        guard Device.type() == .Simulator else { return false }
        
        // if there is more enough to test, return false
        guard contactsTotalCount < 30 else { return false }
        
        return true
    }
    
    private func deleteContact(contact: CNMutableContact) {
        let saveRequest = CNSaveRequest()
        saveRequest.deleteContact(contact)
        do {
            try self.contactStore.executeSaveRequest(saveRequest)
        } catch {
            DEBUGLog("delete contact failed ! - \(error)")
        }
    }
    
    private func addNewContact(contact: CNMutableContact) {
        let saveRequest = CNSaveRequest()
        saveRequest.addContact(contact, toContainerWithIdentifier: nil)
        do {
            try self.contactStore.executeSaveRequest(saveRequest)
        } catch {
            DEBUGLog("saving Contact failed ! - \(error)")
        }
    }
    
    // Chinese names
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
    
    // TODO: -
    
    // English names
    private func generateRandomEnglishFamilyName() -> String {
        let familyNames = ["Aaberg", "Bywater", "Cabana", "Eaddy", "Fabbri", "Gaa", "Hysmith", "Iaccarino", "Juve", "Kaatz", "Lytton", "Maag", "Naatz", "Paasch", "Thomas", "Swift", "Uber", "Vaca", "Waalkes", "Xander"]
        
        let index = Int(arc4random_uniform(UInt32(familyNames.count)))
        return familyNames[index]
    }
    
    private func generateRandomEnglishGivenName() -> String {
        let givenNames = ["Augus", "Banu", "Alexia", "Betty", "Candice", "Delia", "Eileen", "Flora", "Frank", "Geoff", "Hale", "Ivan", "Jerry", "Kevin" ,"Larry", "Marcus", "Nikita", "Page", "Quincy", "Taylor", "Viola", "Zora"]
        
        let index = Int(arc4random_uniform(UInt32(givenNames.count)))
        return givenNames[index]
    }
    
}