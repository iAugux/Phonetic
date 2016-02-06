//
//  UIViewController+PullToDismiss.swift
//  iTranslator
//
//  Created by Augus on 12/7/15.
//  Copyright © 2015 iAugus. All rights reserved.
//

import UIKit


extension UITableViewController {
    
    func configurePullToDismissViewController(backgroundColor: UIColor, fillColor: UIColor) {
        
        tableView?.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
 
            self?.tableView.dg_stopLoading()
            self?.dismissViewControllerAnimated(true, completion: nil)
            
            }, loadingView: nil)
        
        tableView?.dg_setPullToRefreshFillColor(fillColor)
        tableView?.dg_setPullToRefreshBackgroundColor(backgroundColor)
    }

}


extension UIViewController {
    
    func pullToDismissViewController(tableView tableView: UITableView?, backgroundColor: UIColor, fillColor: UIColor) {
                
        tableView?.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            
            tableView?.dg_stopLoading()
            self?.dismissViewControllerAnimated(true, completion: nil)
            
            }, loadingView: nil)
        
        tableView?.dg_setPullToRefreshFillColor(fillColor)
        tableView?.dg_setPullToRefreshBackgroundColor(backgroundColor)

    }
    
}