//
//  BaseTableViewController.swift
//  Phonetic
//
//  Created by Augus on 2/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


let kDismissedAdditionalSettingsVCNotification = "kDismissedAdditionalSettingsVCNotification"

class BaseTableViewController: UITableViewController {
    
    var _title = ""
    
    private let _color = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
    private var blurBackgroundView: BlurImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        blurBackgroundView = BlurImageView(frame: view.bounds)
        tableView.backgroundView  = blurBackgroundView
        tableView.separatorColor  = kNavigationBarBackgroundColor
        tableView.allowsSelection = false
        
        if let _ = navigationController as? SettingsNavigationController {
            configurePullToDismissViewController(UIColor.clear(), fillColor: kNavigationBarBackgroundColor, completionHandler: {
                self.postDismissedNotificationIfNeeded()
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let nav = navigationController as? SettingsNavigationController else { return }
        
        nav.customTitleLabel?.text = _title
        nav.configureCustomBarButtonIfNeeded()
        nav.customBarButton?.alpha = 0
        nav.customTitleLabel?.alpha = 0
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            nav.customBarButton?.alpha = 1
            nav.customTitleLabel?.alpha = 1
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard let nav = navigationController as? SettingsNavigationController else { return }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
            nav.customBarButton?.alpha = 0
            }) { (_) -> Void in
                nav.customBarButton?.removeFromSuperview()
                nav.customBarButton = nil
        }
    }
    
    deinit {
        tableView.dg_removePullToRefresh()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: - Scroll View Delegate
extension BaseTableViewController {
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // TODO: - Direction
        //        if scrollView.panGestureRecognizer.translationInView(scrollView.superview).y > 0 {
        //        }
        prepareForDismissingViewController(true)
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        //        if scrollView.panGestureRecognizer.translationInView(scrollView.superview).y > 0 {
        //        }
        prepareForDismissingViewController(false)
    }
    
    private func makeNavigationBarTransparent(_ transparent: Bool) {
        UIView.animate(withDuration: 0.5) { () -> Void in
            self.navigationController?.navigationBar.alpha = transparent ? 0 : 1
        }
    }
    
    private func prepareForDismissingViewController(_ prepared: Bool) {
        
        guard let nav = navigationController as? SettingsNavigationController else { return }
        
        if !prepared {
            UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
                nav.customTitleLabel?.alpha = 0
                }, completion: { (_) -> Void in
                    
                    nav.customTitleLabel?.text      = self._title
                    nav.customTitleLabel?.font      = nav._font
                    nav.customTitleLabel?.textColor = nav._textColor
            })
        }
        
        UIView.animate(withDuration: 0.3, delay: 0.1, options: UIViewAnimationOptions(), animations: { () -> Void in
            nav.customTitleLabel?.alpha = prepared ? 0 : 1
            nav.customBarButton?.alpha = prepared ? 0 : 1
            }) { (_) -> Void in
                
                if prepared {
                    nav.customTitleLabel?.text      = NSLocalizedString("Pull Down to Dismiss", comment: "")
                    nav.customTitleLabel?.textColor = GLOBAL_CUSTOM_COLOR.withAlphaComponent(0.8)
                    nav.customTitleLabel?.font      = UIFont.systemFont(ofSize: 12.0, weight: -1.0)
                }
                
                UIView.animate(withDuration: 0.3, delay: 0.1, options: UIViewAnimationOptions(), animations: { () -> Void in
                    nav.customTitleLabel?.alpha = 1
                    }, completion: { (_) -> Void in
                        
                })
        }
    }
    
}

// MARK: - Keep `SettingViewController` open after dismissing.
extension BaseTableViewController {
    
    private func postDismissedNotificationIfNeeded() {
        // It is not necessary here, but I prefer to keep it.
        guard UIDevice.current().userInterfaceIdiom != .pad else { return }
        
        guard keepSettingWindowOpen else { return }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: kDismissedAdditionalSettingsVCNotification), object: nil)
    }
    
    func dismissViewController(completion: Closure?) {
        dismiss(animated: true) { () -> Void in
            self.postDismissedNotificationIfNeeded()
            completion?()
        }
    }
    
    private var keepSettingWindowOpen: Bool {
        if UserDefaults.standard.value(forKey: kKeepSettingsWindowOpen) == nil {
            UserDefaults.standard.set(kKeepSettingsWindowOpenDefaultBool, forKey: kKeepSettingsWindowOpen)
            UserDefaults.standard.synchronize()
        }
        return UserDefaults.standard.bool(forKey: kKeepSettingsWindowOpen)
    }
    
}

// MARK: - Table View Delegate
extension BaseTableViewController {
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //  @fixed: iPad refusing to accept clear color
        cell.backgroundColor = UIColor.clear()
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        // change label's text color of Footer View
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = _color
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        // change label's text color of Header View
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = _color
    }
    
}
