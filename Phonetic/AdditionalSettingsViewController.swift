//
//  AdditionalSettingsViewController.swift
//  Phonetic
//
//  Created by Augus on 2/3/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

class AdditionalSettingsViewController: UITableViewController {
    
    private var blurBackgroundView: BlurImageView!
    private var leftBarButtonItem: UIBarButtonItem!
    
    private var shouldHideNavigationItem: Bool {
        // iPad
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            return true
        }
        
        // 6(s) Plus or larger iPhones in the future (maybe).
        if Device.isLargerThanScreenSize(Size.Screen4_7Inch) {
            return UIDevice.currentDevice().orientation.isLandscape
        }
        
        return false
    }
    
    private var hideNavigationItem = false {
        didSet {
            if !hideNavigationItem {
                navigationItem.leftBarButtonItem = leftBarButtonItem
            } else {
                navigationItem.leftBarButtonItem = nil
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationViews()
        configurePullToDismissView(UIColor.clearColor(), fillColor: UIColor.clearColor())

        blurBackgroundView = BlurImageView(frame: view.bounds)
        tableView.backgroundView = blurBackgroundView
        
//        tableView.separatorEffect = UIVibrancyEffect(forBlurEffect: UIBlurEffect(style: .Dark))
//        tableView.separatorColor = UIColor(red: 0.702, green: 0.702, blue: 0.702, alpha: 1.0)
        
    }

    deinit {
        tableView.dg_removePullToRefresh()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        blurBackgroundView?.layoutIfNeeded()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        // Optimized for 6(s) Plus
        if Device.isEqualToScreenSize(Size.Screen5_5Inch) {
            hideNavigationItem = toInterfaceOrientation.isLandscape
        }
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            // TODO: ipad popview 旋转后不在正确的位置
            if let popover = popoverPresentationController {
                print("FFFFF")
                let origin = CGPointMake(UIScreen.screenWidth() / 2, UIScreen.screenHeight() / 3)
                //            let size = CGSizeMake(<#T##width: CGFloat##CGFloat#>, <#T##height: CGFloat##CGFloat#>)
                let rect = CGRect(origin: origin, size: popover.preferredContentSize)
                //                let rect = CGRectMake(UIScreen.screenWidth() / 2, UIScreen.screenHeight() / 3, <#T##width: CGFloat##CGFloat#>, <#T##height: CGFloat##CGFloat#>)
                popover.sourceRect = rect
                popover.setNeedsFocusUpdate()
            }
        }
    }

    private func configureNavigationViews() {
        navigationController?.hidesBarsOnSwipe = true
        navigationController?.completelyTransparentBar()
        title = NSLocalizedString("Additional Settings", comment: "UINavigationController title - Additional Settings")
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.systemFontOfSize(17.0)]

        let image = UIImage(named: "close")?.imageWithRenderingMode(.AlwaysTemplate)
        leftBarButtonItem = UIBarButtonItem(image: image, style: .Plain, target: self, action: "dismissViewController")
        navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        hideNavigationItem = shouldHideNavigationItem
    }
    
    func dismissViewController() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        //  @fixed: iPad refusing to accept clear color
        cell.backgroundColor = UIColor.clearColor()
    }
    
    override func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        // change label's text color of Footer View
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
    }

}


