//
//  UIViewController+PullToDismiss.swift
//
//  Created by Augus on 12/7/15.
//  Copyright © 2015 iAugus. All rights reserved.
//

import UIKit


extension UITableViewController {
    
    func configurePullToDismissViewController(_ backgroundColor: UIColor, fillColor: UIColor, completionHandler: (() -> Void)?) {
        tableView?.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            
            self?.tableView.dg_stopLoading()
            self?.dismiss(animated: true, completion: {
                if let completion = completionHandler {
                    completion()
                }
            })
            
            }, loadingView: nil)
        
        tableView?.dg_setPullToRefreshFillColor(fillColor)
        tableView?.dg_setPullToRefreshBackgroundColor(backgroundColor)
    }
    
}


extension UIViewController {
    
    func pullToDismissViewController(tableView: UITableView?, backgroundColor: UIColor, fillColor: UIColor, completionHandler: (() -> Void)?) {
                
        tableView?.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            
            tableView?.dg_stopLoading()
            self?.dismiss(animated: true, completion: {
                if let completion = completionHandler {
                    completion()
                }
            })
            
            }, loadingView: nil)
        
        tableView?.dg_setPullToRefreshFillColor(fillColor)
        tableView?.dg_setPullToRefreshBackgroundColor(backgroundColor)

    }
    
}
