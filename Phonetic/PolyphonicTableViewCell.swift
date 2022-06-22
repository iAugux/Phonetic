//
//  PolyphonicTableViewCell.swift
//  Phonetic
//
//  Created by Augus on 2/23/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

final class PolyphonicTableViewCell: UITableViewCell {
    var polyphonicKey: String!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var polyphonicLabel: UILabel!
    @IBOutlet var polyphonicSwitch: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.textColor = UIColor.white
        polyphonicLabel.textColor = UIColor.lightGray
        polyphonicSwitch.onTintColor = .vividColor
    }

    @IBAction func polyphonicSwitchDidTap(_ sender: UISwitch) {
        guard let key = polyphonicKey else { return }
        UserDefaults.standard.set(sender.isOn, forKey: key)
    }
}
