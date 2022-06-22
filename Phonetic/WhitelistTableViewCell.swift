//
//  WhitelistTableViewCell.swift
//  Phonetic
//
//  Created by Augus on 5/10/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

final class WhitelistTableViewCell: UITableViewCell {
    var identifier: String?

    @IBOutlet var avatar: UIImageView! {
        didSet {
            avatar.clipsToBounds = true
            avatar.layer.cornerRadius = 22.0
        }
    }

    @IBOutlet var whitelistSwitch: UISwitch! {
        didSet {
            whitelistSwitch.onTintColor = .vividColor
        }
    }

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var phoneticNameLabel: UILabel!
    @IBOutlet var briefNameLabel: UILabel!

    @IBAction func whitelistSwitchDidTap(_ sender: UISwitch) {
        guard let id = identifier else { return }
        whitelistIdentifiers = [id]
    }
}
