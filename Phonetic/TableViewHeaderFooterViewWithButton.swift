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
    
    convenience init(buttonImageName: String) {
        self.init(reuseIdentifier: nil)
        button = UIButton(type: .Custom)
        button.frame.size = CGSizeMake(16, 16)
        button.center = textLabel!.center
        button.frame.origin.x = textLabel!.frame.maxX + 8.0
        button.setImage(UIImage(named: buttonImageName), forState: .Normal)
        button.addTarget(self, action: "buttonDidTap", forControlEvents: .TouchUpInside)
        addSubview(button)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        button?.center = textLabel!.center
        button.frame.origin.x = textLabel!.frame.maxX + 8.0
    }
    
    internal func buttonDidTap() {
       delegate?.tableViewHeaderFooterViewWithButtonDidTap()
    }
    
}
