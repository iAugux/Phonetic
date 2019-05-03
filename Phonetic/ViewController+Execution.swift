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
        if UserDefaults.standard.value(forKey: kEnableAnimation) == nil {
            UserDefaults.standard.set(kEnableAnimationDefaultBool, forKey: kEnableAnimation)
        }
        return UserDefaults.standard.bool(forKey: kEnableAnimation)
    }

    private var shouldEnableAnimation: Bool {
        guard enableAnimation else { return false }
        // guarantee there is no audio playing in the background.
        // e.g: Never pause your music. I don't want to bother you.
        return !AVAudioSession.sharedInstance().isOtherAudioPlaying
    }

    @objc func execute() {
        AppDelegate.shared.requestContactsAccess { [weak self] granted in
            guard let self = self else { return }
            guard granted else { return }
            guard !self.isProcessing else {
                self.alertToAbortIfNeeded()
                return
            }
            self.initializeUI(true)
            self.isProcessing = true
            self.playVideoIfNeeded()
            PhoneticContacts.shared.execute(resultHandler: { currentResult, percentage -> Void in
                self.outputView.text = currentResult
                self.percentageLabel.text = "\(Int(percentage))%"
                self.runProgressBar(false, percentage: percentage)
            }) { aborted -> Void in
                self.avPlayer?.pause()
                self.promoptCompletion(aborted)
            }
        }
    }

    @objc func clean(_ gesture: UIGestureRecognizer) {
        guard gesture is UITapGestureRecognizer || gesture.state == .began else { return }
        clean()
    }

    func clean() {
        AppDelegate.shared.requestContactsAccess { [weak self] granted in
            guard let self = self else { return }
            guard !self.isProcessing else {
                self.alertToAbortIfNeeded()
                return
            }
            let title = NSLocalizedString("Warning!", comment: "UIAlertController - title")
            let message = NSLocalizedString("Are you sure to clean all Mandarin Latin's phonetic keys?", comment: "UIAlertController - message")
            let okActionTitle = NSLocalizedString("Clean", comment: "UIAlertAction title - clean all phonetic keys")
            let cancelActionTitle = NSLocalizedString("Cancel", comment: "UIAlertAction title - do not to clean phonetic keys")
            let appendingMessage = PhoneticContacts.shared.messageOfCurrentKeysNeedToBeCleaned
            let alertController = UIAlertController(title: title, message: message + appendingMessage, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel, handler: nil)
            let okAction = UIAlertAction(title: okActionTitle, style: .default) { _ in
                self.initializeUI(false)
                self.isProcessing = true
                self.playVideoIfNeeded()
                PhoneticContacts.shared.cleanMandarinLatinPhonetic(resultHandler: { currentResult, percentage -> Void in
                    self.percentageLabel.text = "\(100 - Int(percentage))%"
                    self.runProgressBar(true, percentage: percentage)
                }, completionHandler: { aborted -> Void in
                    self.avPlayer?.pause()
                    self.promoptCompletion(aborted)
                })
            }
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }

    // MARK: - Video
    @objc func loopingVideo() {
        guard UIApplication.shared.applicationState == .active && PhoneticContacts.shared.isProcessing else {
            avPlayer?.pause()
            avPlayerController = nil
            return
        }
        avPlayer?.seek(to: CMTimeMakeWithSeconds(0, preferredTimescale: 1))
        avPlayer?.play()
    }

    func pauseVideo() {
        avPlayer?.pause()
        hideBlurViewWithAnimation(false)
    }

    func playVideoIfNeeded() {
        hideBlurViewWithAnimation(true)
        guard shouldEnableAnimation else {
            // stop playing first if it's playing.
            avPlayer?.pause()
            avPlayerController = nil
            return
        }
        // should play now.
        if avPlayerController == nil { configureBackgroundVideo() }
        avPlayer?.play()
    }

    private func configureBackgroundVideo() {
        guard let url = Bundle.main.url(forResource: "wave", withExtension: "mp4") else { return }
        avPlayer = AVPlayer(url: url)
        avPlayerController = AVPlayerViewController()
        avPlayerController.player = avPlayer
        avPlayerController.view.frame = avPlayerPlaceholderView.bounds
        avPlayerController.videoGravity = .resize
        avPlayerController.view.isUserInteractionEnabled = false
        avPlayerController.showsPlaybackControls = false
        avPlayerPlaceholderView.addSubview(avPlayerController.view)
        // loop video
        NotificationCenter.default.addObserver(self, selector: #selector(loopingVideo), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }

    private func hideBlurViewWithAnimation(_ hidden: Bool) {
        UIView.animate(withDuration: 1.2) {
            self.blurView?.effect = !hidden ? UIBlurEffect(style: .light) : nil
        }
        hideLabels(hidden)
    }

    // MARK: - Progress
    private func runProgressBar(_ rollback: Bool, percentage: Double) {
        if !rollback {
            let angle = percentage * 360 / 100
            progress.angle = angle
        } else {
            let angle = (100 - percentage) * 360 / 100
            progress.angle = angle
        }
    }

    private func initializeUI(_ executionCondition: Bool) {
        outputView.text = ""
        if executionCondition {
            percentageLabel.text = "0%"
        } else {
            progress.angle = 360
            percentageLabel.text = "100%"
            outputView.alpha = 0
            outputView.text = "  " + NSLocalizedString("Processing", comment: "") + "..."
            UIView.animate(withDuration: 0.4, animations: {
                self.outputView.alpha = 1
            })
        }
    }

    private func promoptCompletion(_ aborted: Bool) {
        let text = aborted ? NSLocalizedString("Aborted", comment: "") : NSLocalizedString("Completed", comment: "")
        UIView.animate(withDuration: 0.1, delay: 0.3, options: [], animations: {
            self.outputView.alpha = 0
        }) { _ in
            self.outputView.text = text
            UIView.animate(withDuration: 1.2, delay: 0, options: [], animations: {
                self.outputView.alpha = 0.8
            }, completion: { _ in
                UIView.animate(withDuration: 0.9, delay: 0.7, options: [], animations: {
                    self.outputView.alpha = 0
                }, completion: { _ in
                    self.outputView.text = ""
                    self.outputView.alpha = 1
                    self.hideBlurViewWithAnimation(false)
                    self.isProcessing = false
                })
            })
        }
    }
}
