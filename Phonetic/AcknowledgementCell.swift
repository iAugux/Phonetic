//
//  AcknowledgementCell.swift
//  Phonetic
//
//  Created by Augus on 5/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

final class AcknowledgementCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var licenseLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        backgroundColor = UIColor.phoneticLightGray.darker(0.5)
    }
}
