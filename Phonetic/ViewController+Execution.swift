//
//  ViewController+Execution.swift
//  Phonetic
//
//  Created by Augus on 1/27/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit


extension ViewController {
    
    private var enableAnimation: Bool {
        if NSUserDefaults.standardUserDefaults().valueForKey(kEnableAnimation) == nil {
            NSUserDefaults.standardUserDefaults().setBool(kEnableAnimationDefaultBool, forKey: kEnableAnimation)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        return NSUserDefaults.standardUserDefaults().boolForKey(kEnableAnimation)
    }
    
    private var forceEnableAnimation: Bool {
        if NSUserDefaults.standardUserDefaults().valueForKey(kForceEnableAnimation) == nil {
            NSUserDefaults.standardUserDefaults().setBool(kForceEnableAnimationDefaultBool, forKey: kForceEnableAnimation)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        return NSUserDefaults.standardUserDefaults().boolForKey(kForceEnableAnimation)
    }
    
    private var shouldEnableAnimation: Bool {
        if enableAnimation {
            if forceEnableAnimation {
                return true
            }
            // guarantee there is no audio playing in the background.
            // e.g: Never pause your music. I don't want to bother you.
            else if AVAudioSession.sharedInstance().otherAudioPlaying {
                return false
            } else {
                return true
            }
        }
        return false
    }
    
    func execute() {
        
//        guard PhoneticContacts.sharedInstance.enableNickname || PhoneticContacts.sharedInstance.enableCustomName else {
//            let msg = NSLocalizedString("You haven't enable any key for Quick Search!", comment: "")
//            let ok = NSLocalizedString("OK", comment: "")
//            AlertController.alert(title: msg, actionTitle: ok, completionHandler: nil)
//            
//            return
//        }
        
        initializeUI(true)
        
        PhoneticContacts.sharedInstance.execute({ () -> Void in
            self.isProcessing = true
            self.playVideoIfNeeded()
            }, resultHandler: { (currentResult, percentage) -> Void in
                self.outputView.text = currentResult
                self.percentageLabel.text = "\(Int(percentage))%"
                self.runProgressBar(false, percentage: percentage)
            }) { (aborted) -> Void in
                self.avPlayer?.pause()
                self.promoptCompletion(aborted)
        }
    }
    
    func clean(gesture: UIGestureRecognizer) {
        
        // former: UITapGestureRecognizer.
        // the later: ensure be triggered at the beginning while long pressing, or there will be a warning at runtime.
        guard gesture.isKindOfClass(UITapGestureRecognizer) || gesture.state == .Began else { return }
        
        guard PhoneticContacts.sharedInstance.keysToFetchIfNeeded.count != 0 else {
            let msg = NSLocalizedString("You haven't choose any keys for cleaning!", comment: "")
            let ok = NSLocalizedString("OK", comment: "")
            AlertController.alert(title: msg, actionTitle: ok, completionHandler: nil)
            
            return
        }
        
        clean()
    }
    
    func clean() {
        
        let title             = NSLocalizedString("Warning!", comment: "UIAlertController - title")
        let message           = NSLocalizedString("Are you sure to clean all Mandarin Latin's phonetic keys?", comment: "UIAlertController - message")
        let okActionTitle     = NSLocalizedString("Clean", comment: "UIAlertAction title - clean all phonetic keys")
        let cancelActionTitle = NSLocalizedString("Cancel", comment: "UIAlertAction title - do not to clean phonetic keys")
        
        let appendingMessage = PhoneticContacts.sharedInstance.messageOfCurrentKeysNeedToBeCleaned
        
        let alertController   = UIAlertController(title: title, message: message + appendingMessage, preferredStyle: .Alert)
        let cancelAction      = UIAlertAction(title: cancelActionTitle, style: .Cancel, handler: nil)
        let okAction          = UIAlertAction(title: okActionTitle, style: .Default) { (_) -> Void in
            
            self.initializeUI(false)

            PhoneticContacts.sharedInstance.cleanMandarinLatinPhonetic({ () -> Void in
                self.isProcessing = true
                self.playVideoIfNeeded()
                }, resultHandler: { (currentResult, percentage) -> Void in
                    self.percentageLabel.text = "\(100 - Int(percentage))%"
                    self.runProgressBar(true, percentage: percentage)
                }, completionHandler: { (aborted) -> Void in
                    self.avPlayer?.pause()
                    self.promoptCompletion(aborted)
            })
        }
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: - Video
    func loopingVideo(){
        
        guard UIApplication.sharedApplication().applicationState == .Active && PhoneticContacts.sharedInstance.isProcessing else {
            avPlayer?.pause()
            avPlayerController = nil
            return
        }
        
        avPlayer?.seekToTime(CMTimeMakeWithSeconds(0, 1))
        avPlayer?.play()
    }
    
    func pauseVideo() {
        avPlayer?.pause()
        hideBlurVieWithAnimation(false)
    }
    
    func playVideoIfNeeded() {
        hideBlurVieWithAnimation(true)
        
        guard shouldEnableAnimation else {
            // stop playing first if it's playing.
            avPlayer?.pause()
            avPlayerController = nil
            return
        }
        
        // should play now.
        if avPlayerController == nil {
            configureBackgroundVideo()
        }
        
        avPlayer?.play()
    }

    private func configureBackgroundVideo(){
        
        guard let url = NSBundle.mainBundle().URLForResource("wave", withExtension: "mp4") else { return }
        
        avPlayer                                       = AVPlayer(URL: url)
        avPlayerController                             = AVPlayerViewController()
        avPlayerController.player                      = avPlayer
        avPlayerController.view.frame                  = avPlayerPlaceholderView.bounds
        avPlayerController.videoGravity                = AVLayerVideoGravityResize  //AVLayerVideoGravityResizeAspect
        avPlayerController.view.userInteractionEnabled = false
        avPlayerController.showsPlaybackControls       = false
        
        avPlayerPlaceholderView.addSubview(avPlayerController.view)
        
        // loop video
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(loopingVideo), name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }
    
    private func hideBlurVieWithAnimation(hidden: Bool) {
        UIView.animateWithDuration(1.2, animations: { () -> Void in
            self.blurView?.alpha = hidden ? 0 : 0.97
        })
    }
    
    // MARK: - Progress
    private func runProgressBar(rollback: Bool, percentage: Double) {
        if !rollback {
            let angle = percentage * 360 / 100
            progress.angle = angle
        } else {
            let angle = (100 - percentage) * 360 / 100
            progress.angle = angle
            
        }
    }
    
    private func initializeUI(executionCondition: Bool) {
        progress.alpha = 1
        outputView.text = ""
        if executionCondition {
            progress.angle       = 0
            percentageLabel.text = "0%"
        } else {
            progress.angle       = 360
            percentageLabel.text = "100%"
            outputView.alpha     = 0
            outputView.text      = "  " + NSLocalizedString("Processing", comment: "") + "..."
            
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                self.outputView.alpha = 1
            })
        }
    }
    
    private func promoptCompletion(aborted: Bool) {
        
        let text = aborted ? NSLocalizedString("Aborted", comment: "") : NSLocalizedString("Completed", comment: "")
        
        UIView.animateWithDuration(0.1, delay: 0.3, options: .CurveEaseInOut, animations: { () -> Void in
            self.outputView.alpha = 0
            }) { (_) -> Void in
                self.outputView.text = text
                UIView.animateWithDuration(1.2, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
                    self.outputView.alpha = 0.8
                    }, completion: { (_) -> Void in
                        UIView.animateWithDuration(0.9, delay: 0.7, options: .CurveEaseInOut, animations: { () -> Void in
                            self.outputView.alpha = 0
                            self.progress.alpha = 0
                            }, completion: { (_) -> Void in
                                self.outputView.text = ""
                                self.outputView.alpha = 1
                                self.hideBlurVieWithAnimation(false)
                                self.isProcessing = false
                        })
                })
        }
    }
    
    
}
