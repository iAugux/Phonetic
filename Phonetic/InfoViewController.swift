//
//  InfoViewController.swift
//  Phonetic
//
//  Created by Augus on 1/29/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit
import SafariServices

final class InfoViewController: UIViewController, SFSafariViewControllerDelegate {
    @IBOutlet private var versionLabel: UILabel!
    @IBOutlet private var github: UIImageView!
    @IBOutlet private var shareButton: UIButton!
    @IBOutlet private var iTranslatorTopLabel: UILabel!
    @IBOutlet private var iTranslatorBottomLabel: UILabel!
    @IBOutlet private var iTranslatorImageView: AppIconImageView!
    private lazy var leftCustomBarButton: UIButton = {
        let leftCustomBarButton = UIButton(type: .custom)
        leftCustomBarButton.setImage(UIImage(named: "apple_swift"), for: .normal)
        leftCustomBarButton.addTarget(self, action: #selector(leftCustomBarButtonDidTap), for: .touchUpInside)
        return leftCustomBarButton
    }()
    private lazy var rightCustomBarButton: UIButton = {
        let rightCustomBarButton = UIButton(type: .custom)
        rightCustomBarButton.setImage(UIImage(named: "trello"), for: .normal)
        rightCustomBarButton.addTarget(self, action: #selector(rightCustomBarButtonDidTap), for: .touchUpInside)
        return rightCustomBarButton
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureGithubImageView()
        configureVersionLabel()
        configureCustomBarButtonItems()
        guard UIDevice.current.isPad else {
            iTranslatorTopLabel.text = ""
            iTranslatorBottomLabel.text = ""
            return
        }
        shareButton.isHidden = true
        iTranslatorImageView.isHidden = false
        iTranslatorImageView.isUserInteractionEnabled = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: Notification.Name(rawValue: kVCWillDisappearNotification), object: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    private func configureGithubImageView() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(checkOnGithub))
        github.addGestureRecognizer(recognizer)
    }
    
    private func configureVersionLabel() {
        guard let version = APP.version, let build = APP.build else { return }
        versionLabel.text = "Version \(version) (\(build))"
    }
    
    @IBAction func shareButtonDidTap(_ sender: AnyObject) {
        guard !UIDevice.current.isPad else {
            iTranslatorImageView.iconDidTap()
            return
        }
        let text = NSLocalizedString("SharePhoneticContacts", comment: "")
        let appUrl = URL(string: "https://itunes.apple.com/app/id" + "1078961574")!
        let objectsToShare = [text, #imageLiteral(resourceName: "iTunesArtwork"), appUrl] as [Any]
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view
        activityViewController.excludedActivityTypes = [.openInIBooks, .postToVimeo, .addToReadingList, .saveToCameraRoll, .assignToContact, .print]
        dismiss(animated: true, completion: {
            UIApplication.shared.appDelegateWindowTopMostViewController?.present(activityViewController, animated: true, completion: nil)
        })
    }
    
    @objc private func checkOnGithub() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            let safariVC = SFSafariViewController(url: URL(string: "https://github.com/iAugux/Phonetic")!)
            safariVC.delegate = self
            guard let topVC = UIApplication.shared.topMostViewController else { return }
            topVC.present(safariVC, animated: true, completion: nil)
        }
    }

    private func configureCustomBarButtonItems() {
        guard let navBar = navigationController?.navigationBar else { return }
        navBar.addSubview(leftCustomBarButton)
        leftCustomBarButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(25)
            make.centerY.equalToSuperview()
            make.left.equalTo(13)
        }
        navBar.addSubview(rightCustomBarButton)
        rightCustomBarButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.centerY.equalToSuperview()
            make.right.equalTo(-13)
        }
    }
    
    @objc private func leftCustomBarButtonDidTap() {
        guard let view = AppDelegate.shared.window?.rootViewController?.view else { return }
        performSegue(withIdentifier: "PresentAcknowledgementViewController", sender: view)
    }
    
    @objc private func rightCustomBarButtonDidTap() {
        let url = URL(string: "trello://x-callback-url/showBoard?shortlink=FFOaRrJ4")!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
            return
        }
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            let safariVC = SFSafariViewController(url: URL(string: "https://trello.com/b/FFOaRrJ4/phonetic")!)
            safariVC.delegate = self
            UIApplication.shared.topMostViewController?.present(safariVC, animated: true, completion: nil)
        }
    }
}
