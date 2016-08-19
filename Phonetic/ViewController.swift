//
//  ViewController.swift
//  Phonetic
//
//  Created by Augus on 1/27/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Components

let GLOBAL_CUSTOM_COLOR = UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)

class ViewController: UIViewController {
    
    @IBOutlet weak var executeButton: UIButton!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var outputView: UITextView!
    @IBOutlet weak var percentageLabel: UILabel!
    @IBOutlet weak var avPlayerPlaceholderView: UIImageView!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var progress: KDCircularProgress!
    
    fileprivate var singleTap: UITapGestureRecognizer!
    fileprivate var multiTap: UITapGestureRecognizer!
    fileprivate var longPress: UILongPressGestureRecognizer!
    fileprivate var swipeUp: UISwipeGestureRecognizer!
    
    fileprivate var abortingAlertController: UIAlertController!
    
    var avPlayerController: AVPlayerViewController!
    var avPlayer: AVPlayer!
    
    var isProcessing = false {
        didSet {
            settingButton?.isEnabled = !isProcessing
            infoButton?.isEnabled = !isProcessing
            executeButton?.isEnabled = !isProcessing
            enableExecuteButtonGestures(!isProcessing)
            
            // dismiss alert controller if it's already done.
            if !isProcessing {
                abortingAlertController?.dismissViewController()
                abortingAlertController = nil
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubViews()

        Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(rateMeInTheSecondTime), userInfo: nil, repeats: false)
        NotificationCenter.default.addObserver(self, selector: #selector(showLabels), name: NSNotification.Name(rawValue: kVCWillDisappearNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(popoverSettingViewController), name: NSNotification.Name(rawValue: kDismissedAdditionalSettingsVCNotification), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseVideo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // I modified the style while presenting a SFSafariViewController, so here should reset it.
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        displayWalkthroughIfNeeded()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        avPlayer?.pause()
        avPlayerPlaceholderView.subviews.first?.removeFromSuperview()
        avPlayerController = nil
        
        if isProcessing {
            let message = NSLocalizedString("Animation Stopped...", comment: "")
            Toast.make(message, delay: 0, interval: 5)
        }
    }
    
    private func configureSubViews() {
        // execute button
        executeButton?.tintColor = GLOBAL_CUSTOM_COLOR
        executeButton?.setImage(UIImage(named: "touch")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
        
        singleTap = UITapGestureRecognizer(target: self, action: #selector(execute))
        multiTap  = UITapGestureRecognizer(target: self, action: #selector(clean(_:)))
        longPress = UILongPressGestureRecognizer(target: self, action: #selector(clean(_:)))
        multiTap.numberOfTapsRequired = 2
        
        swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(abortActions))
        swipeUp.direction = .up
        
        executeButton.addGestureRecognizer(singleTap)
        executeButton.addGestureRecognizer(multiTap)
        executeButton.addGestureRecognizer(longPress)
        singleTap.require(toFail: multiTap)
        singleTap.require(toFail: longPress)
        
        // setting button
        settingButton.addTarget(self, action: #selector(popoverSettingViewController), for: .touchUpInside)
        
        // info button
        infoButton.addTarget(self, action: #selector(popoverInfoViewController), for: .touchUpInside)
        
        // Preventing multiple buttons from being touched at the same time
//        settingButton.exclusiveTouch = true
//        infoButton.exclusiveTouch = true
        
        if !UIDevice.current.isBlurSupported() || UIAccessibilityIsReduceTransparencyEnabled() {
            blurView.effect = nil
            blurView.backgroundColor = UIColor(red: 0.498, green: 0.498, blue: 0.498, alpha: 0.926)
        }
    }
    
    private func enableExecuteButtonGestures(_ enable: Bool) {
        
        if !enable {
            executeButton?.gestureRecognizers?.removeAll()
            executeButton?.addGestureRecognizer(swipeUp)
        } else {
            executeButton?.removeGestureRecognizer(swipeUp)
            executeButton?.addGestureRecognizer(singleTap)
            executeButton?.addGestureRecognizer(multiTap)
            executeButton?.addGestureRecognizer(longPress)
        }
    }
    
    internal func abortActions() {
        UIView.animate(withDuration: 0.45, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
            self.executeButton?.frame.origin.y -= 25
            }) { (_) -> Void in
              
                UIView.animate(withDuration: 0.35, delay: 0.2, options: UIViewAnimationOptions(), animations: { () -> Void in
                    self.executeButton?.frame.origin.y += 25
                    }, completion: { _ -> Void in
                        self.abortingAlert()
                })
        }
    }
    
    private func abortingAlert() {
        guard isProcessing else { return }
        
        let title = NSLocalizedString("Abort", comment: "UIAlertController - title")
        let message = NSLocalizedString("Processing... Are you sure to abort?", comment: "UIAlertController - message")
        let cancelActionTitle = NSLocalizedString("Cancel", comment: "")
        let okActionTitle = NSLocalizedString("Abort", comment: "")
        
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: okActionTitle, style: .default) { (_) -> Void in
            PhoneticContacts.sharedInstance.isProcessing = false
        }
        
        abortingAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        abortingAlertController.addAction(cancelAction)
        abortingAlertController.addAction(okAction)
        UIApplication.topMostViewController?.present(abortingAlertController, animated: true, completion: nil)
    }
    
}


