//
//  BlurActionSheet.swift
//  BlurActionSheetDemo
//
//  Created by nathan on 15/4/23.
//  Copyright (c) 2015年 nathan. All rights reserved.
//

import UIKit

public class BlurActionSheet: UIView {
    public var titles: [String]?
    public var handler: ((_ index: Int) -> Void)?
    private let actionSheetCellHeight: CGFloat = 44.0
    private let actionSheetCancelHeight: CGFloat = UIDevice.current.hasNotch ? 90 : 58.0
    private var showSet: NSMutableSet = .init()
    private var containerView: UIView?

    private lazy var blurBackgroundView = BlurBackgroundView()
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundView = nil
        tableView.isScrollEnabled = false
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.register(BlurActionSheetCell.self)
        return tableView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(blurBackgroundView, pinningEdges: .all)
        blurBackgroundView.addSubview(tableView, pinningEdges: [.left, .right, .bottom])
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public class func showWithTitles(_ titles: [String], handler: @escaping ((_ index: Int) -> Void)) -> BlurActionSheet {
        return showWithTitles(titles, view: nil, handler: handler)
    }

    public class func showWithTitles(_ titles: [String], view: UIView?, handler: @escaping ((_ index: Int) -> Void)) -> BlurActionSheet {
        let actionSheet = BlurActionSheet(frame: UIScreen.main.bounds)
        actionSheet.titles = titles
        actionSheet.containerView = view
        actionSheet.handler = handler
        actionSheet.show()
        return actionSheet
    }

    private func show() {
        let maxHeight = actionSheetCellHeight * CGFloat(titles!.count - 1) + actionSheetCancelHeight
        tableView.constrainHeight(to: maxHeight)
        if let container = containerView {
            container.addSubview(self, pinningEdges: .all)
        } else {
            UIApplication.shared.topMostViewController?.view.addSubview(self, pinningEdges: .all)
        }
        guard self.superview != nil else { return }
        blurBackgroundView.effect = nil
        UIView.animate(withDuration: 0.3, animations: {
            self.blurBackgroundView.effect = UIBlurEffect(style: .dark)
        })
    }

    private func hide() {
        var index = 0
        for visibleCell in tableView.visibleCells {
            if let cell = visibleCell as? BlurActionSheetCell {
                index = index + 1
                let height = tableView.frame.size.height
                cell.underLineView.alpha = 0.5
                cell.textLabel?.alpha = 0.5
                UIView.animate(withDuration: 0.25, delay: 0.1, options: .curveEaseOut, animations: {
                    cell.layer.transform = CATransform3DTranslate(cell.layer.transform, 0, height * 2, 0)
                }, completion: { _ in self.removeFromSuperview() })
            }
        }
        UIView.animate(withDuration: 0.5, animations: {
            self.blurBackgroundView.effect = nil
        })
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        hide()
        guard let titles = titles else { return }
        handler?(titles.count - 1)
    }
}

extension BlurActionSheet: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles?.count ?? 0
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let titles = titles else { return actionSheetCellHeight }
        return indexPath.row == titles.count - 1 ? actionSheetCancelHeight : actionSheetCellHeight
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: BlurActionSheetCell.self, for: indexPath)
        if indexPath.row == 0 { cell.underLineView.isHidden = true }
        cell.textLabel?.text = titles![indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = UIColor.white
        return cell
    }
}

extension BlurActionSheet: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        hide()
        handler?(indexPath.row)
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !showSet.contains(indexPath) else { return }
        showSet.add(indexPath)
        let delayTime: TimeInterval! = 0.2 + sqrt(Double(indexPath.row)) * 0.09
        cell.layer.transform = CATransform3DTranslate(cell.layer.transform, 0, 400, 0)
        cell.alpha = 0.5
        UIView.animate(withDuration: 0.35, delay: delayTime, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [], animations: {
            cell.layer.transform = CATransform3DIdentity
            cell.alpha = 1
        }, completion: nil)
    }
}
