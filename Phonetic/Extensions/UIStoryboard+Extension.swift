//
//  UIStoryboard+Extension.swift
//
//  Created by Augus on 4/30/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


extension UIStoryboard {
    static var Main: UIStoryboard { return UIStoryboard(name: "Main", bundle: nil) }
}

extension UIStoryboard {
    
    /// Instantiates and returns the view controller with the specified identifier.
    /// Note: withIdentifier must equal to the vc Class
    func instantiateViewController<T : UIViewController>(with vc: T.Type) -> T {
        return instantiateViewController(withIdentifier: String(describing: vc.self)) as! T
    }
}


// MARK: -

extension UITableView {
    
    /// Returns a reusable table-view cell object for the specified reuse identifier and adds it to the table.
    /// Note: withIdentifier must be equal to the Cell Class.
    func dequeueReusableCell<T : UITableViewCell>(with cell: T.Type, for indexPath: IndexPath) -> T {
        return dequeueReusableCell(withIdentifier: String(describing: cell.self), for: indexPath) as! T
    }
    
    /// Registers a nib object containing a cell with the table view under a specified identifier.
    /// Nib name must be equal to the Cell Class, and the forCellReuseIdentifier must equal to Cell Class as well.
    func registerNib(_ cell: Swift.AnyClass) {
        let id = String(describing: cell.self)
        let nib = UINib(nibName: id, bundle: nil)
        register(nib, forCellReuseIdentifier: id)
    }
    
    /// Registers a class for use in creating new table cells.
    /// Note: forCellReuseIdentifier must equal to the Cell Class.
    func register(_ cellClass: Swift.AnyClass) {
        register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
    }
}


// MARK: -

extension UICollectionView {
    
    /// Returns a reusable table-view cell object for the specified reuse identifier and adds it to the table.
    /// Note: withIdentifier must be equal to the Cell Class.
    func dequeueReusableCell<T : UICollectionViewCell>(with cell: T.Type, for indexPath: IndexPath) -> T {
        return dequeueReusableCell(withReuseIdentifier: String(describing: cell.self), for: indexPath) as! T
    }
    
    /// Registers a nib object containing a cell with the table view under a specified identifier.
    /// Nib name must be equal to the Cell Class, and the forCellReuseIdentifier must equal to Cell Class as well.
    func registerNib(_ cell: Swift.AnyClass) {
        let id = String(describing: cell.self)
        let nib = UINib(nibName: id, bundle: nil)
        register(nib, forCellWithReuseIdentifier: id)
    }
    
    /// Registers a class for use in creating new table cells.
    /// Note: forCellReuseIdentifier must equal to the Cell Class.
    func register(_ cellClass: Swift.AnyClass) {
        register(cellClass, forCellWithReuseIdentifier: String(describing: cellClass))
    }
}



// MARK: -

extension UIView {
    
    /// Load view from nib. Note: Nib name must be equal to the class name.
    ///
    /// - parameter view:    class name for the view
    /// - parameter owner:   nib name for the view
    /// - parameter options: options
    ///
    /// - returns: view
    class func loadFromNibAndClass<T : UIView>(_ view: T.Type, owner: Any? = nil, options: [AnyHashable : Any]? = nil) -> T? {
        
        let name = String(describing: view.self)
        
        guard let nib = Bundle.main.loadNibNamed(name, owner: owner, options: options) else { return nil }
        
        return nib.first as? T
    }
}

