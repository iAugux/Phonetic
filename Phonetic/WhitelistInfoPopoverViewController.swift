//
//  WhitelistInfoPopoverViewController.swift
//  Phonetic
//
//  Created by Augus on 5/14/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

final class WhitelistInfoPopoverViewController: UIViewController {
    @IBOutlet var tipsLabel: UILabel! {
        didSet {
            tipsLabel.text = NSLocalizedString("Tips", comment: "")
            tipsLabel.textColor = UIColor.white
        }
    }

    @IBOutlet var textView: UITextView! {
        didSet {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 20.0
            paragraphStyle.maximumLineHeight = 20.0
            paragraphStyle.minimumLineHeight = 20.0
            let ats = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.paragraphStyle: paragraphStyle]
            textView.attributedText = NSAttributedString(string: NSLocalizedString("WhitelistInfo", comment: ""), attributes: ats)
        }
    }

    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        // dismiss current view controller on iPad while rotating, or the WhitelistViewController's position can not be fixed after rotating.
        guard UIDevice.current.isPad else { return }
        dismissAnimated()
    }
}
