//
//  BaseTableViewController.swift
//  Phonetic
//
//  Created by Augus on 2/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit
import Device

class BaseTableViewController: UITableViewController {
    private let _color = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
    private lazy var blurBackgroundView = BlurImageView(frame: view.bounds)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.isBottomHairlineHidden = true
        navigationController?.navigationBar.barTintColor = GLOBAL_LIGHT_GRAY_COLOR
        tableView.backgroundView = blurBackgroundView
        tableView.separatorColor = GLOBAL_LIGHT_GRAY_COLOR

        if #available(iOS 11.0, *) {
            tableView.estimatedSectionHeaderHeight = 0
            tableView.estimatedSectionFooterHeight = 0
        }
        if let sv = UIApplication.shared.topMostViewController?.view {
            tableView.configureRightBottomCornerScrollTrigger(superView: sv, color: GLOBAL_CUSTOM_COLOR.alpha(0.5))
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
}

// MARK: - Table View Delegate
extension BaseTableViewController {
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //  @fixed: iPad refusing to accept clear color
        cell.backgroundColor = UIColor.clear
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        // change label's text color of Footer View
        (view as? UITableViewHeaderFooterView)?.textLabel?.textColor = _color
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        // change label's text color of Header View
        (view as? UITableViewHeaderFooterView)?.textLabel?.textColor = _color
    }
}
