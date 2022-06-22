//
//  WalkthroughViewController.swift
//  Zoom Contacts
//
//  Created by Augus on 4/30/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

let displayedWalthroughKey = "DisplayedWalthroughKey"

// REFERENCE: https://github.com/jorgecasariego/Walkthroughs
final class WalkthroughViewController: UIViewController {
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var headerLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var pageControl: UIPageControl!
    @IBOutlet private var skipButton: UIButton!
    @IBOutlet private var startButton: UIButton!

    var index = 0
    var headerText = ""
    var imageName = ""
    var descriptionText = ""

    lazy var keys: [String] = {
        var keys = [String]()
        keys.append(NSLocalizedString("Nickname", comment: ""))
        // Temporarily set from 1 set filter `Note`
        for i in 1 ..< QuickSearch.cancel.rawValue {
            keys.append(QuickSearch(rawValue: i)!.key)
        }
        return keys
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        headerLabel.text = headerText
        descriptionLabel.text = descriptionText
        imageView.image = UIImage(named: imageName)
        pageControl.currentPage = index
        guard let maxIndex = (parent as? PageViewController)?.maxIndex else { return }
        configureStartButton(maxIndex)
        configureSkipButtonIfNeeded(maxIndex)
        configureCollectionViewIfNeeded()
        configureImageViewIfNeeded()
    }

    private func configureStartButton(_ maxIndex: Int) {
        startButton.setTitle(NSLocalizedString("Get Started", comment: ""), for: .normal)
        startButton.isHidden = (index == maxIndex) ? false : true
        startButton.isUserInteractionEnabled = (index == maxIndex) ? true : false
        startButton.layer.cornerRadius = 5.0
        startButton.layer.masksToBounds = true
    }

    private func configureSkipButtonIfNeeded(_ maxIndex: Int) {
        skipButton.setTitle(NSLocalizedString("Skip", comment: ""), for: .normal)
        let hidden = !UserDefaults.standard.bool(forKey: displayedWalthroughKey, defaultValue: false)
        if hidden {
            skipButton.isHidden = true
        } else {
            skipButton.isHidden = (index == maxIndex) ? true : false
        }
        skipButton.isUserInteractionEnabled = skipButton.isHidden ? false : true
    }

    private func configureCollectionViewIfNeeded() {
        guard index == 2 else {
            collectionView.isHidden = true
            return
        }
        collectionView.dataSource = self
        collectionView.delegate = self
        let row: Int = {
            let userDefaults = UserDefaults.standard
            if PhoneticContacts.shared.enableNickname || !PhoneticContacts.shared.enableCustomName {
                return 0
            } else {
                let rawValue = userDefaults.integer(forKey: kQuickSearchKeyRawValue, defaultValue: QuickSearch.notes.rawValue)
                return rawValue + 1
            }
        }()

        let firstIndexPath = IndexPath(row: row, section: 0)
        collectionView.selectItem(at: firstIndexPath, animated: false, scrollPosition: [])
    }

    private func configureImageViewIfNeeded() {
        guard index == 3 else { return }
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(imageViewDidTap))
        imageView.addGestureRecognizer(recognizer)
        imageView.isUserInteractionEnabled = true
    }

    @objc private func imageViewDidTap() {
        let vc = UIStoryboard.Main.instantiateViewController(with: HelpManualViewController.self)
        let nav = UINavigationController(rootViewController: vc)
        nav.makeNavBarCompletelyTransparent()
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(image: .close, style: .done, target: self, action: .dismissAnimated)
        present(nav, animated: true, completion: nil)
    }

    @IBAction func startClicked() {
        UserDefaults.standard.set(true, forKey: displayedWalthroughKey)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func skipClicked() {
        startClicked()
//        guard !UserDefaults.standard().bool(forKey: displayedWalthroughKey, defaultValue: false) else {
//            startClicked()
//            return
//        }
//        let msg = NSLocalizedString("Are you sure to skip?", comment: "")
//        let skip = NSLocalizedString("Skip", comment: "")
//        AlertController.alertWithCancelAction(title: msg, actionTitle: skip, completionHandler: {
//            self.startClicked()
//        }, canceledHandler: nil)
    }
}
