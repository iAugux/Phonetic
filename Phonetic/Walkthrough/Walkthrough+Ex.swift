//
//  Walkthrough+Ex.swift
//  Zoom Contacts
//
//  Created by Augus on 4/30/16.
//  Copyright © 2016 iAugus. All rights reserved.
//


import UIKit


func displayWalkthroughIfNeeded(transparent transparent: Bool = true, completion: CompletionHandler? = nil) {

    guard !NSUserDefaults.standardUserDefaults().boolForKey(displayedWalthroughKey) else { return }
    
    displayWalkthrough(transparent: transparent, completion: completion)
}

func displayWalkthrough(transparent transparent: Bool = true, completion: CompletionHandler? = nil) {
    
    guard let pageViewController = WorkthroughSB.instantiateViewControllerWithIdentifier(String(PageViewController)) as? PageViewController else { return }
    
    transparent ? pageViewController.modalPresentationStyle = .OverCurrentContext : ()
    
    UIDevice.isPad ? pageViewController.modalTransitionStyle = .CrossDissolve : ()
    
    UIApplication.topMostViewController?.presentViewController(pageViewController, animated: true, completion: {
        completion?()        
    })
    
}
