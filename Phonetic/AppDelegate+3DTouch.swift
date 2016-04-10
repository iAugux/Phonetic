//
//  AppDelegate+3DTouch.swift
//  Phonetic
//
//  Created by Augus on 4/2/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit



extension AppDelegate {
    
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        
        // react to shortcut item selections
        debugPrint("A shortcut item was pressed. It was ", shortcutItem.localizedTitle)
        
        switch shortcutItem.type {
            case Type.Excute.rawValue:   execute()
            case Type.Rollback.rawValue: rollback()
            default: return
        }
        
    }
    
    private enum Type: String {
        case Excute
        case Rollback
    }
    
    
    // MARK: Springboard Shortcut Items (dynamic)
    
    func createShortcutItemsWithIcons() {
        
        let executeIcon   = UIApplicationShortcutIcon(type: .Add)
        let rollbackIcon = UIApplicationShortcutIcon(templateImageName: "rollback_3d")
        
        let executeItemTitle = NSLocalizedString("Add Phonetic Keys", comment: "")
        let rollbackItemTitle = NSLocalizedString("Clean Phonetic Keys", comment: "")
        
        // create dynamic shortcut items
        let executeItem = UIMutableApplicationShortcutItem(type: Type.Excute.rawValue, localizedTitle: executeItemTitle, localizedSubtitle: nil, icon: executeIcon, userInfo: nil)
        let rollbackItem = UIMutableApplicationShortcutItem(type: Type.Rollback.rawValue, localizedTitle: rollbackItemTitle, localizedSubtitle: nil, icon: rollbackIcon, userInfo: nil)
        
        // add all items to an array
        let items = [executeItem, rollbackItem]
        
        UIApplication.sharedApplication().shortcutItems = items
    }
    
    
    // MARK: - Actions
    
    private func execute() {
        viewController?.execute()
    }
    
    private func rollback() {
        viewController?.clean()
    }
    
    private var viewController: ViewController? {
        
        // ensure root vc is presenting.
        window?.rootViewController?.presentedViewController?.dismissViewControllerWithoutAnimation()
        
        return window?.rootViewController as? ViewController
    }

}