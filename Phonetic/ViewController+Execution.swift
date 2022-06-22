//
//  ViewController+Execution.swift
//  Phonetic
//
//  Created by Augus on 1/27/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import ASKit
import UIKit

extension ViewController {
    @objc func execute() {
        let isQuickSearchNoteKey: Bool = {
            guard !PhoneticContacts.shared.enableNickname else { return false }
            guard PhoneticContacts.shared.enableCustomName else { return false }
            guard let quickSearchKey = UserDefaults.standard.value(forKey: kQuickSearchKeyRawValue) as? Int else { return false }
            return quickSearchKey == QuickSearch.notes.rawValue
        }()
        if #available(iOS 13.0, *), isQuickSearchNoteKey {
            AlertController.alert(NSLocalizedString("Due to the restriction on iOS 13+, we can't use the `Notes` key at this moment. Please disable the key in settings.", comment: ""), actionTitle: .ok)
            return
        }
        AppDelegate.shared.requestContactsAccess { [weak self] granted in
            guard let self = self else { return }
            guard granted else { return }
            guard !self.isProcessing else {
                self.alertToAbortIfNeeded()
                return
            }
            self.initializeUI(true)
            self.isProcessing = true
            self.playAnimations()
            PhoneticContacts.shared.execute(resultHandler: { currentResult, percentage in
                self.runProgressBar(false, percentage: percentage)
                self.outputView.fadeTransition(0.45)
                self.outputView.text = currentResult
                self.percentageLabel.text = "\(Int(percentage))%"
            }) { aborted in
                self.starsOverlay.stopAnimating()
                self.promoptCompletion(aborted)
            }
        }
    }

    @objc func clean(_ gesture: UIGestureRecognizer) {
        guard gesture is UITapGestureRecognizer || gesture.state == .began else { return }
        clean()
    }

    func clean() {
        if #available(iOS 13.0, *), PhoneticContacts.shared.shouldCleanNotesKeys {
            AlertController.alert(NSLocalizedString("Due to the restriction on iOS 13+, we can't use the `Notes` key at this moment. Please disable the key in settings.", comment: ""), actionTitle: .ok)
            return
        }
        AppDelegate.shared.requestContactsAccess { [weak self] _ in
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
                self.playAnimations()
                PhoneticContacts.shared.cleanMandarinLatinPhonetic(resultHandler: { _, percentage in
                    self.percentageLabel.text = "\(100 - Int(percentage))%"
                    self.runProgressBar(true, percentage: percentage)
                }, completionHandler: { aborted in
                    self.starsOverlay.stopAnimating()
                    self.promoptCompletion(aborted)
                })
            }
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }

    // MARK: - Animations
    func stopAnimations() {
        starsOverlay.stopAnimating()
        hideBlurViewWithAnimation(false)
    }

    func playAnimations() {
        hideBlurViewWithAnimation(true)
        starsOverlay.startAnimating()
    }

    private func hideBlurViewWithAnimation(_ hidden: Bool) {
        UIView.animate(withDuration: 1.2) {
            self.blurView?.effect = !hidden ? UIBlurEffect(style: .dark) : nil
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
