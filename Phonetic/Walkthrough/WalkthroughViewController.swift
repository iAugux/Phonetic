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
        
        for i in 0 ..< QuickSearch.Cancel.rawValue {
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
        
        guard let maxIndex = (parentViewController as? PageViewController)?.maxIndex else { return }
       
        configureStartButton(maxIndex)
        configureSkipButtonIfNeeded(maxIndex)
        configureCollectionViewIfNeeded()
        configureImageViewIfNeeded()
    }
    
    private func configureStartButton(maxIndex: Int) {
        startButton.setTitle(NSLocalizedString("Get Started", comment: ""), forState: .Normal)
        startButton.hidden = (index == maxIndex) ? false : true
        startButton.userInteractionEnabled = (index == maxIndex) ? true : false
        startButton.layer.cornerRadius = 5.0
        startButton.layer.masksToBounds = true
    }
    
    private func configureSkipButtonIfNeeded(maxIndex: Int) {
        
        skipButton.setTitle(NSLocalizedString("Skip", comment: ""), forState: .Normal)
        
        let hidden = !NSUserDefaults.standardUserDefaults().getBool(displayedWalthroughKey, defaultKeyValue: false)
        
        if hidden {
            skipButton.hidden = true
        } else {
            skipButton.hidden = (index == maxIndex) ? true : false
        }
        
        skipButton.userInteractionEnabled = skipButton.hidden ? false : true
    }
    
    private func configureCollectionViewIfNeeded() {

        guard index == 2 else {
            collectionView.hidden = true
            return
        }
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        let row: Int = {
            let userDefaults = NSUserDefaults.standardUserDefaults()
            
            if PhoneticContacts.sharedInstance.enableNickname || !PhoneticContacts.sharedInstance.enableCustomName {
                return 0
                
            } else {
                let rawValue = userDefaults.getInteger(kQuickSearchKeyRawValue, defaultKeyValue: QuickSearch.MiddleName.rawValue)
                return rawValue + 1
            }
        }()
        
        let firstIndexPath = NSIndexPath(forRow: row, inSection: 0)
        collectionView.selectItemAtIndexPath(firstIndexPath, animated: false, scrollPosition: .None)
    }
    
    private func configureImageViewIfNeeded() {
        
        guard index == 3 else { return }
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(imageViewDidTap))
        imageView.addGestureRecognizer(recognizer)
        imageView.userInteractionEnabled = true
    }
    
    @objc private func imageViewDidTap() {

        guard let vc = UIStoryboard.Main.instantiateViewControllerWithIdentifier(String(HelpManualViewController)) as? HelpManualViewController else { return }
                
        let nav = UINavigationController(rootViewController: vc)
        nav.completelyTransparentBar()
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "close"), style: .Plain, target: self, action: #selector(dismissViewController))
        presentViewController(nav, animated: true, completion: nil)
    }

    @IBAction func startClicked() {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: displayedWalthroughKey)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func skipClicked() {
        
        startClicked()
        
//        guard !NSUserDefaults.standardUserDefaults().getBool(displayedWalthroughKey, defaultKeyValue: false) else {
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