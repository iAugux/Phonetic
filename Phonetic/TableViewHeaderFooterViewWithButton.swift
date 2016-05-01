//
//  TableViewHeaderFooterViewWithButton.swift
//  Phonetic
//
//  Created by Augus on 2/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

protocol TableViewHeaderFooterViewWithButtonDelegate {
    func tableViewHeaderFooterViewWithButtonDidTap()
}

class TableViewHeaderFooterViewWithButton: UITableViewHeaderFooterView {
    
    var delegate: TableViewHeaderFooterViewWithButtonDelegate!
    
    private var button: UIButton!
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    convenience init(buttonImageName name: String, tintColor: UIColor = .whiteColor(), twinkleInterval: NSTimeInterval = 0.7) {
        self.init(reuseIdentifier: nil)
        button = UIButton(type: .Custom)
        button.frame.size = CGSizeMake(18, 18)
        button.center = textLabel!.center
        button.frame.origin.x = textLabel!.frame.maxX + 8.0
        button.tintColor = tintColor
        button.setImage(UIImage(named: name)?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        button.addTarget(self, action: #selector(buttonDidTap), forControlEvents: .TouchUpInside)
        addSubview(button)
        
        button?.twinkling(twinkleInterval, minAlpha: 0.2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        button?.center = textLabel!.center
        button.frame.origin.x = textLabel!.frame.maxX + 8.0
    }
    
    @objc private func buttonDidTap() {
       delegate?.tableViewHeaderFooterViewWithButtonDidTap()
    }
    
}
