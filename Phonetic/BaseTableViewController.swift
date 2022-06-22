//
//  BaseTableViewController.swift
//  Phonetic
//
//  Created by Augus on 2/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

class BaseTableViewController: UITableViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .phoneticLightGray
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        tableView.separatorColor = UIColor.phoneticLightGray.darker(0.45)
        tableView.backgroundColor = UIColor.phoneticLightGray.darker(0.3)
        tableView.backgroundView = UIView()
        if #available(iOS 11.0, *) {
            tableView.estimatedSectionHeaderHeight = 0
            tableView.estimatedSectionFooterHeight = 0
        }
    }
}

// MARK: - Table View Delegate
extension BaseTableViewController {
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //  @fixed: iPad refusing to accept clear color
        cell.backgroundColor = UIColor.clear
    }

    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        // change label's text color of Footer View
        (view as? UITableViewHeaderFooterView)?.textLabel?.textColor = UIColor(hex: 0xD9D9D9)
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        // change label's text color of Header View
        (view as? UITableViewHeaderFooterView)?.textLabel?.textColor = UIColor(hex: 0xD9D9D9)
    }
}
