//
//  WalkthroughViewController.swift
//  Zoom Contacts
//
//  Created by Augus on 4/30/16.
//  Copyright © 2016 iAugus. All rights reserved.
//


// REFERENCE: https://github.com/jorgecasariego/Walkthroughs


import UIKit


let displayedWalthroughKey = "DisplayedWalthroughKey"

class WalkthroughViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var startButton: UIButton!

    var index = 0
    var headerText = ""
    var imageName = ""
    var descriptionText = ""
    
    lazy var keys: [String] = {
        
        var keys = [String]()
        keys.append(NSLocalizedString("Nickname", comment: ""))
        
        for i in 0 ..< QuickSearch.cancel.rawValue {
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
    
    fileprivate func configureStartButton(_ maxIndex: Int) {
        startButton.setTitle(NSLocalizedString("Get Started", comment: ""), for: UIControlState())
        startButton.isHidden = (index == maxIndex) ? false : true
        startButton.isUserInteractionEnabled = (index == maxIndex) ? true : false
        startButton.layer.cornerRadius = 5.0
        startButton.layer.masksToBounds = true
    }
    
    fileprivate func configureSkipButtonIfNeeded(_ maxIndex: Int) {
        
        skipButton.setTitle(NSLocalizedString("Skip", comment: ""), for: UIControlState())
        
        let hidden = !UserDefaults.standard.bool(forKey: displayedWalthroughKey, defaultValue: false)
        
        if hidden {
            skipButton.isHidden = true
        } else {
            skipButton.isHidden = (index == maxIndex) ? true : false
        }
        
        skipButton.isUserInteractionEnabled = skipButton.isHidden ? false : true
    }
    
    fileprivate func configureCollectionViewIfNeeded() {

        guard index == 2 else {
            collectionView.isHidden = true
            return
        }
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        let row: Int = {
            let userDefaults = UserDefaults.standard
            
            if PhoneticContacts.sharedInstance.enableNickname || !PhoneticContacts.sharedInstance.enableCustomName {
                return 0
                
            } else {
                let rawValue = userDefaults.integer(forKey: kQuickSearchKeyRawValue, defaultValue: QuickSearch.middleName.rawValue)
                return rawValue + 1
            }
        }()
        
        let firstIndexPath = IndexPath(row: row, section: 0)
        collectionView.selectItem(at: firstIndexPath, animated: false, scrollPosition: [])
    }
    
    fileprivate func configureImageViewIfNeeded() {
        
        guard index == 3 else { return }
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(imageViewDidTap))
        imageView.addGestureRecognizer(recognizer)
        imageView.isUserInteractionEnabled = true
    }
    
    @objc fileprivate func imageViewDidTap() {

        guard let vc = UIStoryboard.Main.instantiateViewController(withIdentifier: String(HelpManualViewController.self)) as? HelpManualViewController else { return }
                
        let nav = UINavigationController(rootViewController: vc)
        nav.completelyTransparentBar()
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "close"), style: .plain, target: self, action: #selector(dismissViewController))
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
//        
//        let msg = NSLocalizedString("Are you sure to skip?", comment: "")
//        let skip = NSLocalizedString("Skip", comment: "")
//
//        AlertController.alertWithCancelAction(title: msg, actionTitle: skip, completionHandler: { 
//            self.startClicked()
//            }, canceledHandler: nil)
    }
    
}
