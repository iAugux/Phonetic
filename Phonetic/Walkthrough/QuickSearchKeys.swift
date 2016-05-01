//
//  QuickSearchKeys.swift
//  Zoom Contacts
//
//  Created by Augus on 5/1/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

extension WalkthroughViewController: UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return keys.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(String(QuickSearchKeyCell), forIndexPath: indexPath) as! QuickSearchKeyCell
        
        cell.keyLabel.text = keys[indexPath.row]
        
        return cell
    }
}

extension WalkthroughViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        switch indexPath.row {
        case 0:
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: kEnableNickname)
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: kEnableCustomName)
        default:
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: kEnableNickname)
            NSUserDefaults.standardUserDefaults().setInteger(indexPath.row - 1, forKey: kQuickSearchKeyRawValue)
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: kEnableCustomName)
        }
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}


class QuickSearchKeyCell: UICollectionViewCell {
    
    @IBOutlet weak var keyLabel: UILabel!
    
    @IBOutlet private weak var imageView: UIImageView! {
        didSet {
            let color = UIColor(red: 0.5722, green: 0.0, blue: 0.9806, alpha: 1.0)
            imageView.backgroundColor = color
            imageView.layer.cornerRadius = 7.0
            imageView.layer.shadowColor = color.CGColor
            imageView.layer.shadowOffset = CGSizeMake(1, 1)
            imageView.layer.shadowOpacity = 0.5
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let customBackgroundView = CustomSelectedBackgroundView()
        selectedBackgroundView = customBackgroundView
        selectedBackgroundView?.backgroundColor = UIColor.clearColor()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    
}