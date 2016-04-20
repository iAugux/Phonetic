//
//  BlurActionSheetCell.swift
//  BlurActionSheetDemo
//
//  Created by nathan on 15/4/23.
//  Copyright (c) 2015年 nathan. All rights reserved.
//

import UIKit

class BlurActionSheetCell: UITableViewCell {

    private let underLineColor = UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1.0)
    
    var underLineView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        underLineView = UIView()
        underLineView.backgroundColor = underLineColor
        contentView.addSubview(underLineView)
        underLineView.snp_makeConstraints { (make) in
            make.top.equalTo(0)
            make.left.equalTo(8)
            make.right.equalTo(-8)
            make.height.equalTo(0.5)
        }
        
        backgroundView = nil
        backgroundColor = UIColor.clearColor()
        selectedBackgroundView = UIView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            self.textLabel?.textColor = UIColor.lightGrayColor()
            underLineView?.backgroundColor = underLineColor
        }
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            self.textLabel?.textColor = UIColor.lightGrayColor()
            underLineView?.backgroundColor = underLineColor
        }
    }

}
