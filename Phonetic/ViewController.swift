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
    
    private var singleTap: UITapGestureRecognizer!
    private var multiTap: UITapGestureRecognizer!
    private var longPress: UILongPressGestureRecognizer!
    private var swipeUp: UISwipeGestureRecognizer!
    
    private var cancelingAlertController: UIAlertController!
    
    var avPlayerController: AVPlayerViewController!
    var avPlayer: AVPlayer!
    
    var isProcessing = false {
        didSet {
            settingButton?.enabled = !isProcessing
            infoButton?.enabled = !isProcessing
            executeButton?.enabled = !isProcessing
            enableExecuteButtonGestures(!isProcessing)
            
            // dismiss alert controller if it's already done.
            if !isProcessing {
                cancelingAlertController?.dismissViewController()
                cancelingAlertController = nil
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubViews()
        
        NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "rateMeInTheThirdTime", userInfo: nil, repeats: false)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showLabels", name: kVCWillDisappearNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "popoverSettingViewController", name: kDismissedAdditionalSettingsVCNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        pauseVideo()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // I modified the style while presenting a SFSafariViewController, so here should reset it.
        UIApplication.sharedApplication().statusBarStyle = .LightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        avPlayer?.pause()
        avPlayerPlaceholderView.subviews.first?.removeFromSuperview()
        avPlayerController = nil
    }
    
    private func configureSubViews() {
        // execute button
        executeButton?.tintColor = GLOBAL_CUSTOM_COLOR
        executeButton?.setImage(UIImage(named: "touch")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        
        singleTap = UITapGestureRecognizer(target: self, action: "execute")
        multiTap  = UITapGestureRecognizer(target: self, action: "clear:")
        longPress = UILongPressGestureRecognizer(target: self, action: "clear:")
        multiTap.numberOfTapsRequired = 2
        
        swipeUp = UISwipeGestureRecognizer(target: self, action: "cancelActions")
        swipeUp.direction = .Up
        
        executeButton.addGestureRecognizer(singleTap)
        executeButton.addGestureRecognizer(multiTap)
        executeButton.addGestureRecognizer(longPress)
        singleTap.requireGestureRecognizerToFail(multiTap)
        singleTap.requireGestureRecognizerToFail(longPress)
        
        // setting button
        settingButton.addTarget(self, action: "popoverSettingViewController", forControlEvents: .TouchUpInside)
        
        // info button
        infoButton.addTarget(self, action: "popoverInfoViewController", forControlEvents: .TouchUpInside)
        
        // Preventing multiple buttons from being touched at the same time
//        settingButton.exclusiveTouch = true
//        infoButton.exclusiveTouch = true
        
    }
    
    private func enableExecuteButtonGestures(enable: Bool) {
        
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
    
    internal func cancelActions() {
        print("canceled")

        UIView.animateWithDuration(0.5, delay: 0, options: .TransitionNone, animations: { () -> Void in
            self.executeButton?.frame.origin.y -= 25
            }) { (_) -> Void in
              
                UIView.animateWithDuration(0.5, delay: 0.3, options: .TransitionNone, animations: { () -> Void in
                    self.executeButton?.frame.origin.y += 25
                    }, completion: { _ -> Void in
                        self.alertCanceling({ () -> Void in
                            
                        })
                })
        }
    }
    
    private func alertCanceling(abortHandler: (() -> Void)) {
        let title = NSLocalizedString("Abort", comment: "UIAlertController - title")
        let message = NSLocalizedString("Processing... Are you sure to abort?", comment: "UIAlertController - message")
        let cancelActionTitle = NSLocalizedString("Cancel", comment: "")
        let okActionTitle = NSLocalizedString("Abort", comment: "")
        
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: okActionTitle, style: .Default) { (_) -> Void in
            abortHandler()
        }
        
        cancelingAlertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        cancelingAlertController.addAction(cancelAction)
        cancelingAlertController.addAction(okAction)
        UIApplication.topMostViewController()?.presentViewController(cancelingAlertController, animated: true, completion: nil)
    }
}



