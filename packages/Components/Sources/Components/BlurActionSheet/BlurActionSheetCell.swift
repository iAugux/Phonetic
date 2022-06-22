//
//  BlurActionSheetCell.swift
//  BlurActionSheetDemo
//
//  Created by nathan on 15/4/23.
//  Copyright (c) 2015年 nathan. All rights reserved.
//

import ASKit
import UIKit

class BlurActionSheetCell: UITableViewCell {
    private let underLineColor = UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1.0)

    lazy var underLineView: UIView = {
        let underLineView = UIView()
        underLineView.backgroundColor = underLineColor
        return underLineView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundView = nil
        backgroundColor = UIColor.clear
        selectedBackgroundView = UIView()
        contentView.addSubview(underLineView)
        contentView.addSubview(underLineView, pinningEdges: [.top, .left, .right], withInsets: UIEdgeInsets(horizontal: 8, vertical: 0))
        underLineView.constrainHeight(to: 1 / UIScreen.main.scale)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        guard selected else { return }
        textLabel?.textColor = UIColor.lightGray
        underLineView.backgroundColor = underLineColor
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        guard highlighted else { return }
        textLabel?.textColor = UIColor.lightGray
        underLineView.backgroundColor = underLineColor
    }
}
