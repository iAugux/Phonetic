//
//  Walkthrough+Ex.swift
//  Zoom Contacts
//
//  Created by Augus on 4/30/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import ASKit
import UIKit

func displayWalkthroughIfNeeded(_ transparent: Bool = true, completion: Closure? = nil) {
    guard !UserDefaults.standard.bool(forKey: displayedWalthroughKey) else { return }
    displayWalkthrough(transparent, completion: completion)
}

func displayWalkthrough(_ transparent: Bool = true, completion: Closure? = nil) {
    let pageViewController = WorkthroughSB.instantiateViewController(with: PageViewController.self)
    transparent ? pageViewController.modalPresentationStyle = .overCurrentContext : ()
    UIDevice.current.isPad ? pageViewController.modalTransitionStyle = .crossDissolve : ()
    UIApplication.shared.topMostViewController?.present(pageViewController, animated: true, completion: {
        completion?()
    })
}
