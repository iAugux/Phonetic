//
//  HelpManualViewController.swift
//  Phonetic
//
//  Created by Augus on 2/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

final class HelpManualViewController: UIViewController {
    @IBOutlet private var settingButton: UIButton!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var contactsLabel: UILabel! {
        didSet {
            if #available(iOS 10.0, *) { contactsLabel.text = NSLocalizedString("Contacts", comment: "") }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let attributedText = createAttributedString(fullString: descriptionLabel.text!, fullStringColor: .white, subString: ["DISABLE", "关闭", "關閉"], subStringColor: #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1))
        descriptionLabel.attributedText = attributedText
        view.backgroundColor = UIColor.phoneticLightGray.darker(0.3)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = NSLocalizedString("Help Manual", comment: "Navigation title")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        settingButton.flash(duration: 0.6, minAlpha: 0.3, maxAlpha: 1)
    }

    private func createAttributedString(fullString: String, fullStringColor: UIColor, subString: [String], subStringColor: UIColor) -> NSMutableAttributedString {
        let rangeArr = subString.map { (fullString as NSString).range(of: $0) }
        let attributedString = NSMutableAttributedString(string: fullString)
        let font = descriptionLabel.font!
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 0.25 * font.lineHeight
        let attributes = [
            NSAttributedString.Key.foregroundColor: fullStringColor,
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
        ]
        attributedString.addAttributes(attributes, range: NSRange(location: 0, length: fullString.count))
        do {
            let paragraphStyle = NSMutableParagraphStyle()
            let newFont = font.withSize(15.5)
            paragraphStyle.paragraphSpacing = 0.3 * newFont.lineHeight
            let attributes = [
                NSAttributedString.Key.foregroundColor: subStringColor,
                NSAttributedString.Key.font: newFont,
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
            ]
            rangeArr.forEach { attributedString.addAttributes(attributes, range: $0) }
        }
        return attributedString
    }

    @IBAction func openSystemSettings(_ sender: AnyObject) {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString))
    }
}

extension HelpManualViewController {
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        guard UIDevice.current.isPad else { return }
        dismissAnimated()
    }
}
