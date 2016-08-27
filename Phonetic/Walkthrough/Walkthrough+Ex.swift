//
//  Walkthrough+Ex.swift
//  Zoom Contacts
//
//  Created by Augus on 4/30/16.
//  Copyright © 2016 iAugus. All rights reserved.
//


import UIKit


func displayWalkthroughIfNeeded(_ transparent: Bool = true, completion: Closure? = nil) {

    guard !UserDefaults.standard.bool(forKey: displayedWalthroughKey) else { return }
    
    displayWalkthrough(transparent, completion: completion)
}

func displayWalkthrough(_ transparent: Bool = true, completion: Closure? = nil) {
    
    guard let pageViewController = WorkthroughSB.instantiateViewController(withIdentifier: String(PageViewController.self)) as? PageViewController else { return }
    
    transparent ? pageViewController.modalPresentationStyle = .overCurrentContext : ()
    
    UIDevice.isPad ? pageViewController.modalTransitionStyle = .crossDissolve : ()
    
    UIApplication.topMostViewController?.present(pageViewController, animated: true, completion: {
        completion?()        
    })
    
}
