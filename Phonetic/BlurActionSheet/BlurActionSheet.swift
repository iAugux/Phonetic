//
//  BlurActionSheet.swift
//  BlurActionSheetDemo
//
//  Created by nathan on 15/4/23.
//  Copyright (c) 2015年 nathan. All rights reserved.
//

import UIKit
import SnapKit


class BlurActionSheet: UIView, UITableViewDataSource {

    private let actionSheetCellHeight: CGFloat = 44.0
    private let actionSheetCancelHeight: CGFloat = 58.0
    
    private var showSet: NSMutableSet = NSMutableSet()
    var titles: [String]?
    private var containerView: UIView?
    var handler: ((_ index: Int) -> Void)?
    
    private var tableView: UITableView!
    private var blurBackgroundView: BlurBackgroundView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        blurBackgroundView = BlurBackgroundView()
        addSubview(blurBackgroundView)
        blurBackgroundView.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }

        tableView                 = UITableView()
        tableView.delegate        = self
        tableView.dataSource      = self
        tableView.backgroundView  = nil
        tableView.isScrollEnabled   = false
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle  = .none
        tableView.tableFooterView = UIView()
        blurBackgroundView.addSubview(tableView)
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func showWithTitles(_ titles: [String], handler: @escaping ((_ index: Int) -> Void)) -> BlurActionSheet {
        return showWithTitles(titles, view: nil, handler: handler)
    }
    
    class func showWithTitles(_ titles: [String], view: UIView?, handler: @escaping ((_ index: Int) -> Void)) -> BlurActionSheet {
        let actionSheet = BlurActionSheet(frame: UIScreen.main.bounds)
        actionSheet.titles = titles
        actionSheet.containerView = view
        actionSheet.handler = handler
        actionSheet.show()
        
        return actionSheet
    }
    
    private func show() {
        
        let maxHeight = actionSheetCellHeight * CGFloat(titles!.count - 1) + actionSheetCancelHeight

        tableView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalTo(blurBackgroundView)
            make.height.equalTo(maxHeight)
        }
        
        if (containerView != nil) {
            containerView!.addSubview(self)
        } else {
            UIApplication.topMostViewController?.view.addSubview(self)
        }
        
        guard self.superview != nil else { return }
        
        snp.makeConstraints({ (make) in
            make.edges.equalTo(0)
        })
        
        blurBackgroundView.effect = nil
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.blurBackgroundView.effect = UIBlurEffect(style: .dark)
        })
    }
    
    private func hide() {
        
        var index = 0
        
        for visibleCell in tableView.visibleCells {
            if let cell = visibleCell as? BlurActionSheetCell {
                index = index + 1
                let height = tableView.frame.size.height

                cell.underLineView?.alpha = 0.5
                cell.textLabel?.alpha = 0.5
                
                UIView.animate(withDuration: 0.25, delay: 0.1, options: .curveEaseOut, animations: { () -> Void in
                    cell.layer.transform = CATransform3DTranslate(cell.layer.transform, 0, height * 2, 0)
                    }, completion: { (Bool) -> Void in
                        self.removeFromSuperview()
                })
            }
        }
        
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
           self.blurBackgroundView.effect = nil
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        hide()
        if let handler = handler {
            if let titles = titles {
                handler(titles.count - 1)
            }
        }
    }
    
    // MARK: - tableView dataSource and delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (titles != nil) {
            return titles!.count
        } else {
            return 0
        }
    }
    
    @objc(tableView:heightForRowAtIndexPath:) func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let titles = titles {
            return indexPath.row == titles.count - 1 ? actionSheetCancelHeight : actionSheetCellHeight
        }
        return actionSheetCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "actionSheetCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? BlurActionSheetCell
        if (cell == nil) {
            cell = BlurActionSheetCell(style: .default, reuseIdentifier: cellIdentifier)
        }
        
        if (indexPath.row == 0) {
            cell?.underLineView.isHidden = true
        }
        
        cell?.textLabel?.text = titles![indexPath.row]
        cell?.textLabel?.textAlignment = .center
        cell?.textLabel?.textColor = UIColor.white
        
        return cell!
    }
    
}

extension BlurActionSheet: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        hide()
        if let handler = handler {
            handler(indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if (!showSet.contains(indexPath)) {
            showSet.add(indexPath)
            
            let delayTime: TimeInterval! = 0.2 + sqrt(Double(indexPath.row)) * 0.09
            cell.layer.transform = CATransform3DTranslate(cell.layer.transform, 0, 400, 0)
            cell.alpha = 0.5
            
            UIView.animate(withDuration: 0.35, delay: delayTime, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: UIViewAnimationOptions(), animations: { () -> Void in
                
                cell.layer.transform = CATransform3DIdentity
                cell.alpha = 1
                
                }, completion: nil)
        }
    }
}
