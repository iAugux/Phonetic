//
//  ViewController.swift
//  Phonetic
//
//  Created by Augus on 1/27/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import ASKit
import Components
import UIKit

final class ViewController: UIViewController {
    @IBOutlet var executeButton: UIButton!
    @IBOutlet var blurView: UIVisualEffectView!
    @IBOutlet var outputView: UILabel!
    @IBOutlet var percentageLabel: UILabel!
    @IBOutlet var starsOverlay: StarsOverlay!
    @IBOutlet var settingButton: UIButton!
    @IBOutlet var infoButton: UIButton!
    @IBOutlet var progress: KDCircularProgress!
    private var isStatusBarHidden = false

    override var prefersStatusBarHidden: Bool {
        return UIDevice.current.hasNotch ? isStatusBarHidden : false
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    private var abortingAlertController: UIAlertController!

    var isProcessing = false {
        didSet {
            settingButton.isEnabled = !isProcessing
            infoButton.isEnabled = !isProcessing
            isStatusBarHidden = isProcessing
            UIView.animate(withDuration: 0.25) {
                self.setNeedsStatusBarAppearanceUpdate()
                [self.settingButton, self.infoButton].forEach {
                    $0.alpha = $0.isEnabled ? 1 : 0
                }
            }
            executeButton.isEnabled = !isProcessing
            enableExecuteButtonGestures(!isProcessing)
            // dismiss alert controller if it's already done.
            guard !isProcessing else { return }
            abortingAlertController?.dismissAnimated()
            abortingAlertController = nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubViews()
        NotificationCenter.default.addObserver(self, selector: #selector(showLabels), name: NSNotification.Name(rawValue: kVCWillDisappearNotification), object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAnimations()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        displayWalkthroughIfNeeded()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        starsOverlay.stopAnimating()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    // MARK: Contents
    private lazy var singleTap = UITapGestureRecognizer(target: self, action: #selector(execute))
    private lazy var longPress = UILongPressGestureRecognizer(target: self, action: #selector(clean(_:)))
    private lazy var multiTap: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(clean(_:)))
        gesture.numberOfTapsRequired = 2
        return gesture
    }()

    private lazy var swipeUp: UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(abortActions))
        gesture.direction = .up
        return gesture
    }()

    // MARK: Private
    private func configureSubViews() {
        if #available(iOS 13.0, *) {
            outputView.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
        }
        percentageLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .semibold)
        // progress
        progress.setColors(.iconColorOne, .iconColorTwo, .iconColorThree, .iconColorFour)
        // execute button
        executeButton.tintColor = .vividColor
        executeButton.setImage(UIImage(named: "touch")?.withRenderingMode(.alwaysTemplate), for: .normal)
        // gestures
        executeButton.addGestureRecognizer(singleTap)
        executeButton.addGestureRecognizer(multiTap)
        executeButton.addGestureRecognizer(longPress)
        singleTap.require(toFail: multiTap)
        singleTap.require(toFail: longPress)
        // setting button
        settingButton.addTarget(self, action: #selector(popoverSettingViewController), for: .touchUpInside)
        // info button
        infoButton.addTarget(self, action: #selector(popoverInfoViewController), for: .touchUpInside)
        guard !UIDevice.current.isBlurSupported || UIAccessibility.isReduceTransparencyEnabled else { return }
        blurView.effect = nil
        blurView.backgroundColor = UIColor(red: 0.498, green: 0.498, blue: 0.498, alpha: 0.926)
    }

    private func enableExecuteButtonGestures(_ enable: Bool) {
        if !enable {
            executeButton.gestureRecognizers?.removeAll()
            executeButton.addGestureRecognizer(swipeUp)
        } else {
            executeButton.removeGestureRecognizer(swipeUp)
            executeButton.addGestureRecognizer(singleTap)
            executeButton.addGestureRecognizer(multiTap)
            executeButton.addGestureRecognizer(longPress)
        }
    }

    @objc private func abortActions() {
        UIView.animate(withDuration: 0.45, delay: 0, options: [], animations: {
            self.executeButton.frame.origin.y -= 25
        }) { _ in
            UIView.animate(withDuration: 0.35, delay: 0.2, options: [], animations: {
                self.executeButton.frame.origin.y += 25
            }, completion: { _ in self.alertToAbortIfNeeded() })
        }
    }

    func alertToAbortIfNeeded() {
        guard isProcessing else { return }
        let title = NSLocalizedString("Abort", comment: "UIAlertController - title")
        let message = NSLocalizedString("Processing... Are you sure to abort?", comment: "UIAlertController - message")
        let cancelActionTitle = NSLocalizedString("Cancel", comment: "")
        let okActionTitle = NSLocalizedString("Abort", comment: "")
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: okActionTitle, style: .default) { _ in PhoneticContacts.shared.isProcessing = false }
        abortingAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        abortingAlertController.preferredAction = okAction
        abortingAlertController.addAction(cancelAction)
        abortingAlertController.addAction(okAction)
        UIApplication.shared.topMostViewController?.present(abortingAlertController, animated: true, completion: nil)
    }
}
