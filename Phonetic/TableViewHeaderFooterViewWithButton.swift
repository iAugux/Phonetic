//
//  TableViewHeaderFooterViewWithButton.swift
//  Phonetic
//
//  Created by Augus on 2/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import ASKit
import UIKit

final class TableViewHeaderFooterViewWithButton: UITableViewHeaderFooterView {
    var tapHandler: Closure?

    private lazy var button: ASButton = {
        let button = ASButton(type: .custom)
        button.clickableArea = .init(uniform: 60)
        button.frame.size = CGSize(width: 18, height: 18)
        button.center = textLabel!.center
        button.frame.origin.x = textLabel!.frame.maxX + 8.0
        button.addTarget(self, action: #selector(buttonDidTap), for: .touchUpInside)
        return button
    }()

    convenience init(buttonImageName name: String, flashDuration: TimeInterval = 1.5) {
        self.init(reuseIdentifier: nil)
        button.setImage(UIImage(named: name), for: .normal)
        addSubview(button)
        button.flash(duration: flashDuration, minAlpha: 0.5)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let textLabel = textLabel else { return }
        button.center = textLabel.center
        button.frame.origin.x = textLabel.frame.maxX + 8.0 + compatibleSafeAreaInsets.left
    }

    @objc private func buttonDidTap() {
        tapHandler?()
    }
}
