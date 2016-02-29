//
//  PolyphonicTableViewCell.swift
//  Phonetic
//
//  Created by Augus on 2/23/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

class PolyphonicTableViewCell: UITableViewCell {
    
    var polyphonicKey: String!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var polyphonicLabel: UILabel!
    @IBOutlet weak var polyphonicSwitch: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.textColor = UIColor.whiteColor()
        polyphonicLabel.textColor = UIColor.lightGrayColor()
        polyphonicSwitch.onTintColor = GLOBAL_CUSTOM_COLOR
    }

    @IBAction func polyphonicSwitchDidTap(sender: UISwitch) {
        if let key = polyphonicKey {
            NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey: key)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }

}
