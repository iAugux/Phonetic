//
//  BaseTableViewController.swift
//  Phonetic
//
//  Created by Augus on 2/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

class BaseTableViewController: UITableViewController {
    
    private var blurBackgroundView: BlurImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        blurBackgroundView = BlurImageView(frame: view.bounds)
        tableView.backgroundView = blurBackgroundView
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
