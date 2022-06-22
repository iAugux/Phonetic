//
//  InfoViewController.swift
//  Phonetic
//
//  Created by Augus on 1/29/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import ASKit
import UIKit

final class InfoViewController: UIViewController {
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
        iTranslatorTopLabel.text = ""
        iTranslatorBottomLabel.text = ""
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
        let text = NSLocalizedString("SharePhoneticContacts", comment: "")
        let appUrl = URL(string: "https://itunes.apple.com/app/id" + "1078961574")!
        let objectsToShare = [text, #imageLiteral(resourceName: "iTunesArtwork"), appUrl] as [Any]
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view
        activityViewController.excludedActivityTypes = [.openInIBooks, .postToVimeo, .addToReadingList, .saveToCameraRoll, .assignToContact, .print]
        dismiss(animated: true, completion: {
            UIApplication.shared.topMostViewController?.present(activityViewController, animated: true, completion: nil)
        })
    }

    @objc private func checkOnGithub() {
        dismiss(animated: true) {
            UIApplication.shared.open(URL(string: "https://github.com/iAugux/Phonetic"))
        }
    }

    private func configureCustomBarButtonItems() {
        guard let navBar = navigationController?.navigationBar else { return }
        navBar.addSubview(leftCustomBarButton, pinningEdges: .left, withInsets: UIEdgeInsets(uniform: 13))
        leftCustomBarButton.constrainSize(to: CGSize(uniform: 25))
        leftCustomBarButton.centerYAnchor.constraint(equalTo: navBar.centerYAnchor).isActive = true
        navBar.addSubview(rightCustomBarButton, pinningEdges: .right, withInsets: UIEdgeInsets(uniform: 13))
        rightCustomBarButton.constrainSize(to: CGSize(uniform: 16))
        rightCustomBarButton.centerYAnchor.constraint(equalTo: navBar.centerYAnchor).isActive = true
    }

    @objc private func leftCustomBarButtonDidTap() {
        guard let vc = AppDelegate.shared.window?.rootViewController else { return }
        dismiss(animated: true) {
            let nav = UIStoryboard(name: "Acknowlegement", bundle: nil).instantiateViewController(withIdentifier: "AcknowledgeNavigationController")
            vc.present(nav, animated: true, completion: nil)
        }
    }

    @objc private func rightCustomBarButtonDidTap() {
        let url = URL(string: "trello://x-callback-url/showBoard?shortlink=FFOaRrJ4")!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return
        }
        dismiss(animated: true) {
            UIApplication.shared.open(URL(string: "https://trello.com/b/FFOaRrJ4/phonetic"))
        }
    }
}
