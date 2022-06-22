//  ASKit.swift
//  Created by Augus <iAugux@gmail.com>.
//  Copyright © 2015-2020 iAugus. All rights reserved.

#if os(iOS)
    import UIKit
#elseif os(OSX)
    import AppKit
#endif

// MARK: - Typealias
public typealias Closure = () -> Void
public typealias Handler<T> = (T) -> Void
public typealias HandlerII<T, U> = (T, U) -> Void

// MARK: - Global functions
/// Call something but don't do anything to it. like `let _ = something`
@inline(never) // prevents the passed argument from being optimized away by the compiler
public func touch(_ any: Any?) {}
/// Returns `f(x)` if `x` is non-`nil`; otherwise returns `nil`
@discardableResult public func given<T, U>(_ x: T?, _ f: (T) -> U?) -> U? { return x != nil ? f(x!) : nil }
@discardableResult public func given<T, U, V>(_ x: T?, _ y: U?, _ f: (T, U) -> V?) -> V? { return (x != nil && y != nil) ? f(x!, y!) : nil }

/// Initializes and configures a given NSObject.
/// This utility method can be used to cut down boilerplate code.
public func create<T: NSObject>(constructing construct: (T) -> Void) -> T {
    let obj = T()
    construct(obj)
    return obj
}

/// Helper to do something like: `let foo: T = SomeOptionalT ?? preconditionFailure()`
public func preconditionFailure<T>(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> T {
    Swift.preconditionFailure(message(), file: file, line: line)
}

public func abstract(function: String = #function, file: StaticString = #file, line: UInt = #line) -> Never {
    Swift.preconditionFailure("Abstract method not implemented", file: file, line: line)
}

public func ceil(_ size: CGSize) -> CGSize {
    return CGSize(width: ceil(size.width), height: ceil(size.height))
}

public enum ASDirection { case horizontal, vertical }
public enum ASHorizontalDirection { case left, right }
public enum ASVerticalDirection { case up, down }

// MARK: - Global variables & constants
/// Check is this a 64bit device
public let IS_64_BIT = MemoryLayout<Int>.size == MemoryLayout<Int64>.size
/// This will always return `.zero` in share extension
public let iPhoneXExtraMargins: UIEdgeInsets = { if #available(iOS 11.0, *) { return UIWindow().safeAreaInsets } else { return .zero } }()

// MARK: - Swift.Optional + Extensions
public extension Swift.Optional where Wrapped: Numeric {
    var zeroIfNil: Wrapped { return self == nil ? .zero : self! }
}

public extension Swift.Optional where Wrapped == String {
    var emptyIfNil: String { return self == nil ? "" : self! }
}

// MARK: - NSObject + Extensions
public extension NSObject {
    var className: String { String(describing: Self.self) }
}

// MARK: - String + Extensions
public extension String {
    init?(number: Int, zero: String?, singular: String, pluralFormat: String) {
        switch number {
        case 0: if let zero = zero { self.init(zero) } else { return nil }
        case 1: self.init(singular)
        default: self.init(pluralFormat)
        }
    }
}

public extension String {
    /// Get a formatted string based on the number passed.
    /// - parameter format: `NSLocalizedString` containing one `%@` for where the conditionalized numbered string goes, e.g. `NSLocalizedString(@"You Have %@", nil)`, or simply `"%@"` (the default) without `NSLocalizedString` if there're no other words to be localized.
    /// - parameter number: The number you want to conditionalize on.
    /// - parameter zero: `NSLocalizedString` containing no placeholders (optional), e.g. `NSLocalizedString(@"No Friend", nil)`.
    /// - parameter singular: `NSLocalizedString` containing no placeholders, `e.g. NSLocalizedString(@"One Friend", nil)`.
    /// - parameter pluralFormat: `NSLocalizedString` containing one `%@` for where the conditionalized number goes, e.g. `NSLocalizedString(@"%@ Friends", nil)`.
    init(format: String = "%@", number: Decimal, zero: String? = nil, singular: String, pluralFormat: String) {
        let numberString: String
        if number == 0, let zero = zero {
            numberString = zero
        } else if abs(number) == 1 {
            numberString = singular
        } else {
            numberString = String(format: pluralFormat, number as NSNumber)
        }
        self = String(format: format, numberString)
    }

    init(format: String = "%@", number: Int, zero: String? = nil, singular: String, pluralFormat: String) {
        self.init(format: format, number: Decimal(number), zero: zero, singular: singular, pluralFormat: pluralFormat)
    }
}

// MARK: - UIStoryboard、Xib Extensions
public extension UIStoryboard {
    /// Instantiates and returns the view controller with the specified identifier.
    /// Note: withIdentifier must equal to the vc Class
    func instantiateViewController<T: UIViewController>(with vc: T.Type) -> T {
        return instantiateViewController(withIdentifier: String(describing: vc.self)) as! T
    }

    static var Main: UIStoryboard { return UIStoryboard(name: "Main", bundle: nil) }
}

public extension UITableView {
    /// Returns a reusable table-view cell object for the specified reuse identifier and adds it to the table.
    /// Note: withIdentifier must be equal to the Cell Class.
    func dequeueReusableCell<T: UITableViewCell>(with cell: T.Type, for indexPath: IndexPath) -> T {
        return dequeueReusableCell(withIdentifier: String(describing: cell.self), for: indexPath) as! T
    }

    /// Returns a reusable table-view cell object for the specified reuse identifier and adds it to the table.
    /// Note: withIdentifier must be equal to the Cell Class.
    func dequeueReusableCell<T: UITableViewCell>(with cell: T.Type) -> T {
        return dequeueReusableCell(withIdentifier: String(describing: cell.self)) as! T
    }

    /// Returns a reusable header or footer view located by its identifier.
    /// Note: withIdentifier must be equal to the View Class.
    func dequeueReusableHeaderFooterView<T: UITableViewHeaderFooterView>(with view: T.Type) -> T {
        return dequeueReusableHeaderFooterView(withIdentifier: String(describing: view.self)) as! T
    }

    /// Registers a nib object containing a cell with the table view under a specified identifier.
    /// Nib name must be equal to the Cell Class, and the forCellReuseIdentifier must equal to Cell Class as well.
    func registerNib(_ cellClass: Swift.AnyClass) {
        let id = String(describing: cellClass.self)
        let nib = UINib(nibName: id, bundle: nil)
        register(nib, forCellReuseIdentifier: id)
    }

    /// Registers a class for use in creating new table cells.
    /// Note: forCellReuseIdentifier must equal to the Cell Class.
    func register(_ cellClass: Swift.AnyClass) {
        register(cellClass, forCellReuseIdentifier: String(describing: cellClass.self))
    }

    /// Registers a class for use in creating new table header or footer views.
    /// Note: forHeaderFooterViewReuseIdentifier must equal to the UITableViewHeaderFooterView Class.
    func registerHeaderFooterViewClass(_ headerFooterViewClass: Swift.AnyClass) {
        register(headerFooterViewClass, forHeaderFooterViewReuseIdentifier: String(describing: headerFooterViewClass.self))
    }

    /// Registers a nib object containing a header or footer with the table view under a specified identifier.
    /// Nib name must be equal to the UITableViewHeaderFooterView Class, and the forHeaderFooterViewReuseIdentifier must equal to UITableViewHeaderFooterView Class as well.
    func registerHeaderFooterViewNib(_ headerFooterViewClass: Swift.AnyClass) {
        let id = String(describing: headerFooterViewClass.self)
        let nib = UINib(nibName: id, bundle: nil)
        register(nib, forHeaderFooterViewReuseIdentifier: id)
    }
}

public extension UICollectionView {
    /// Returns a reusable table-view cell object for the specified reuse identifier and adds it to the table.
    /// Note: withIdentifier must be equal to the Cell Class.
    func dequeueReusableCell<T: UICollectionViewCell>(with cell: T.Type, for indexPath: IndexPath) -> T {
        return dequeueReusableCell(withReuseIdentifier: String(describing: cell.self), for: indexPath) as! T
    }

    /// Registers a nib object containing a cell with the table view under a specified identifier.
    /// Nib name must be equal to the Cell Class, and the forCellReuseIdentifier must equal to Cell Class as well.
    func registerNib(_ cellClass: Swift.AnyClass) {
        let id = String(describing: cellClass.self)
        let nib = UINib(nibName: id, bundle: nil)
        register(nib, forCellWithReuseIdentifier: id)
    }

    /// Registers a class for use in creating new table cells.
    /// Note: forCellReuseIdentifier must equal to the Cell Class.
    func register(_ cellClass: Swift.AnyClass) {
        register(cellClass, forCellWithReuseIdentifier: String(describing: cellClass.self))
    }

    func registerHeader(_ headerClass: Swift.AnyClass) {
        register(headerClass, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: String(describing: headerClass.self))
    }

    func registerFooter(_ footerClass: Swift.AnyClass) {
        register(footerClass, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: String(describing: footerClass.self))
    }

    func registerHeaderViewNib(_ header: Swift.AnyClass) {
        let id = String(describing: header.self)
        let nib = UINib(nibName: id, bundle: nil)
        register(nib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: id)
    }

    func registerFooterViewNib(_ footer: Swift.AnyClass) {
        let id = String(describing: footer.self)
        let nib = UINib(nibName: id, bundle: nil)
        register(nib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: id)
    }

    func dequeueReusableHeader<T: UIView>(with view: T.Type, for indexPath: IndexPath) -> T {
        let id = String(describing: view.self)
        return dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: id, for: indexPath) as! T
    }

    func dequeueReusableFooter<T: UIView>(with view: T.Type, for indexPath: IndexPath) -> T {
        let id = String(describing: view.self)
        return dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: id, for: indexPath) as! T
    }
}

public extension UIView {
    /// Load view from nib. Note: Nib name must be equal to the class name.
    static func loadFromNib() -> Self { return loadFromNib(self) }
    private static func loadFromNib<T: UIView>(_ type: T.Type) -> T {
        return Bundle.main.loadNibNamed(String(describing: type), owner: nil, options: nil)![0] as! T
    }

    @available(iOS, renamed: "loadFromNib")
    static func loadFromNibAndClass<T: UIView>(_ view: T.Type, owner: Any? = nil, options: [UINib.OptionsKey: Any]? = nil) -> T? {
        let name = String(describing: view.self)
        guard let nib = Bundle.main.loadNibNamed(name, owner: owner, options: options) else { return nil }
        return nib.first as? T
    }
}

// MARK: - UIScreen Extensions
public extension UIScreen {
    static var width: CGFloat { return UIScreen.main.bounds.width }
    static var height: CGFloat { return UIScreen.main.bounds.height }
}

// MARK: - CGRect Extensions
public extension CGRect {
    /// Returns a larger(or smaller if `height < 0`) height rect with same origin.
    func withExtra(width: CGFloat, height: CGFloat) -> CGRect {
        return inset(by: UIEdgeInsets(top: 0, left: 0, bottom: -height, right: -width))
    }
}

// MARK: - UITableView, UICollectionView, UITableViewCell, UICollectionViewCell, IndexPath extensions
public extension UITableView {
    var centerPoint: CGPoint { return CGPoint(x: center.x + contentOffset.x, y: center.y + contentOffset.y) }
    var centerCellIndexPath: IndexPath? { return indexPathForRow(at: centerPoint) }
    var visibleIndexPath: [IndexPath] { return visibleCells.compactMap { indexPath(for: $0) } }
    func cellForRow(at location: CGPoint) -> UITableViewCell? {
        guard let indexPath = indexPathForRow(at: location) else { return nil }
        return cellForRow(at: indexPath)
    }

    func reloadData(with animation: UITableView.RowAnimation) {
        reloadSections(IndexSet(integersIn: 0 ..< numberOfSections), with: animation)
    }

    func reloadVisibleRows(with animation: UITableView.RowAnimation = .none) {
        guard let ips = indexPathsForVisibleRows else { return }
        reloadRows(at: ips, with: animation)
    }
}

public extension UITableViewCell {
    var relatedTableView: UITableView? {
        var view = superview
        while view != nil && !(view is UITableView) { view = view?.superview }
        return view as? UITableView
    }

    func hideSeparator(_ flag: Bool = true) {
        separatorInset.right = .greatestFiniteMagnitude
    }
}

public extension UICollectionView {
    var centerPoint: CGPoint { return CGPoint(x: center.x + contentOffset.x, y: center.y + contentOffset.y) }
    var centerItemIndexPath: IndexPath? { return indexPathForItem(at: centerPoint) }
    var visibleIndexPath: [IndexPath] { return visibleCells.compactMap { indexPath(for: $0) } }
}

public extension UICollectionViewCell {
    var relatedCollectionView: UICollectionView? {
        var view = superview
        while view != nil && !(view is UICollectionView) { view = view?.superview }
        return view as? UICollectionView
    }
}

public extension IndexPath {
    // Actually there is no difference between `row` and `item`.
    func offsetBy(row: Int, section: Int = 0) -> IndexPath {
        return IndexPath(row: self.row + row, section: self.section + section)
    }

    func offsetBy(item: Int, section: Int = 0) -> IndexPath {
        return IndexPath(row: self.item + item, section: self.section + section)
    }
}

// MARK: - UITabBarController Extensions
extension UITabBarController {
    /// If the selected view controller is a navigation controller, then return the top view controller.
    var selectedTopViewController: UIViewController? {
        guard let selected = selectedViewController else { return nil }
        if let nav = selected as? UINavigationController { return nav.topViewController } else { return selected }
    }
}

// MARK: - UITabBar Extensions
public extension UITabBar {
    func frameOfItem(at index: Int) -> CGRect {
        var frames: [CGRect] = subviews.compactMap { if let v = $0 as? UIControl { return v.frame } else { return nil } }
        frames.sort { $0.origin.x < $1.origin.x }
        if frames.count > index { return frames[index] }
        return frames.last ?? .zero
    }

    func indexOfItem(at point: CGPoint) -> Int? {
        var frames: [CGRect] = subviews.compactMap { if let v = $0 as? UIControl { return v.frame } else { return nil } }
        frames.sort { $0.origin.x < $1.origin.x }
        for (index, rect) in frames.enumerated() { if rect.contains(point) { return index } }
        return nil
    }
}

// MARK: - UIDevice Extensions
public extension UIDevice {
    /// Normally, we don't need to detect iPhone X family device.
    /// Didn't use `UIApplication.shard.window` so that we can use it in app extensions.
    var hasNotch: Bool { return UIWindow().compatibleSafeAreaInsets.bottom > 0 }
    @available(iOS, deprecated, message: "please use: `hasNotch`")
    var isIPhoneX: Bool { return UIDevice.current.userInterfaceIdiom == .phone && UIScreen.main.nativeBounds.height == 2436 }
    var isPad: Bool { return UIDevice.current.userInterfaceIdiom == .pad }
    var isSimulator: Bool { let code = hardwareVersion; return code == "i386" || code == "x86_64" }
    var hardwareVersion: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let versionCode = String(utf8String: NSString(bytes: &systemInfo.machine, length: Int(_SYS_NAMELEN), encoding: String.Encoding.ascii.rawValue)!.utf8String!)!
        return versionCode
    }
}

public extension UIDevice {
    var isScreen3_5Inch: Bool {
        let w = UIScreen.main.bounds.width
        let h = UIScreen.main.bounds.height
        return max(w, h) == 480
    }

    var isScreen4Inch: Bool {
        let w = UIScreen.main.bounds.width
        let h = UIScreen.main.bounds.height
        return max(w, h) == 568
    }

    var isScreen4_7Inch: Bool {
        let w = UIScreen.main.bounds.width
        let h = UIScreen.main.bounds.height
        return max(w, h) == 667 && UIScreen.main.scale != 3.0
    }

    var isScreen5_5Inch: Bool {
        let w = UIScreen.main.bounds.width
        let h = UIScreen.main.bounds.height
        let m = max(w, h)
        return m == 736 || (m == 667 && UIScreen.main.scale == 3.0)
    }
}

// MARK: - UIView + AutoLayout
public extension UIView {
    var compatibleSafeAreaInsets: UIEdgeInsets { if #available(iOS 11.0, *) { return safeAreaInsets } else { return .zero } }
    var safeTopAnchor: NSLayoutYAxisAnchor { if #available(iOS 11.0, *) { return safeAreaLayoutGuide.topAnchor } else { return topAnchor } }
    var safeLeftAnchor: NSLayoutXAxisAnchor { if #available(iOS 11.0, *) { return safeAreaLayoutGuide.leftAnchor } else { return leftAnchor } }
    var safeRightAnchor: NSLayoutXAxisAnchor { if #available(iOS 11.0, *) { return safeAreaLayoutGuide.rightAnchor } else { return rightAnchor } }
    var safeBottomAnchor: NSLayoutYAxisAnchor { if #available(iOS 11.0, *) { return safeAreaLayoutGuide.bottomAnchor } else { return bottomAnchor } }
}

public extension NSLayoutConstraint {
    @discardableResult func with(priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}

public extension UILayoutPriority {
    static var pseudoRequired: UILayoutPriority { return UILayoutPriority(rawValue: 999) }
    static var lowCompressionResistance: UILayoutPriority { return UILayoutPriority(rawValue: 740) }
    static var defaultCompressionResistance: UILayoutPriority { return UILayoutPriority(rawValue: 750) }
    static var highCompressionResistance: UILayoutPriority { return UILayoutPriority(rawValue: 760) }
    static var medium: UILayoutPriority { return UILayoutPriority(rawValue: 500) }
    static var lowHuggingPriority: UILayoutPriority { return UILayoutPriority(rawValue: 240) }
    static var defaultHuggingPriority: UILayoutPriority { return UILayoutPriority(rawValue: 250) }
    static var highHuggingPriority: UILayoutPriority { return UILayoutPriority(rawValue: 260) }
}

public extension UIView {
    func addSubview(_ subview: UIView, pinningEdges edges: UIRectEdge, withInsets insets: UIEdgeInsets = .zero) {
        addSubview(subview)
        subview.pinEdges(edges, to: self, withInsets: insets, useSafeArea: false)
    }

    func addSubview(_ subview: UIView, pinningEdgesToSafeArea edges: UIRectEdge, withInsets insets: UIEdgeInsets = .zero) {
        addSubview(subview)
        subview.pinEdges(edges, to: self, withInsets: insets, useSafeArea: true)
    }

    func insertSubview(_ subview: UIView, at index: Int, pinningEdges edges: UIRectEdge, withInsets insets: UIEdgeInsets = .zero) {
        insertSubview(subview, at: index)
        subview.pinEdges(edges, to: self, withInsets: insets, useSafeArea: false)
    }

    func insertSubview(_ subview: UIView, at index: Int, pinningEdgesToSafeArea edges: UIRectEdge, withInsets insets: UIEdgeInsets = .zero) {
        insertSubview(subview, at: index)
        subview.pinEdges(edges, to: self, withInsets: insets, useSafeArea: true)
    }

    func insertSubview(_ subview: UIView, aboveSubview siblingSubview: UIView, pinningEdges edges: UIRectEdge, withInsets insets: UIEdgeInsets = .zero) {
        insertSubview(subview, aboveSubview: siblingSubview)
        subview.pinEdges(edges, to: self, withInsets: insets, useSafeArea: false)
    }

    func insertSubview(_ subview: UIView, aboveSubview siblingSubview: UIView, pinningEdgesToSafeArea edges: UIRectEdge, withInsets insets: UIEdgeInsets = .zero) {
        insertSubview(subview, aboveSubview: siblingSubview)
        subview.pinEdges(edges, to: self, withInsets: insets, useSafeArea: true)
    }

    func insertSubview(_ subview: UIView, belowSubview siblingSubview: UIView, pinningEdges edges: UIRectEdge, withInsets insets: UIEdgeInsets = .zero) {
        insertSubview(subview, belowSubview: siblingSubview)
        subview.pinEdges(edges, to: self, withInsets: insets, useSafeArea: false)
    }

    func insertSubview(_ subview: UIView, belowSubview siblingSubview: UIView, pinningEdgesToSafeArea edges: UIRectEdge, withInsets insets: UIEdgeInsets = .zero) {
        insertSubview(subview, belowSubview: siblingSubview)
        subview.pinEdges(edges, to: self, withInsets: insets, useSafeArea: true)
    }

    /// - Returns: [.left, .top, .right, .bottom]
    @discardableResult
    func pinEdges(_ edges: UIRectEdge = .all, to view: UIView, withInsets insets: UIEdgeInsets = .zero, useSafeArea: Bool = false) -> [NSLayoutConstraint] {
        guard edges != [] else { preconditionFailure() }
        translatesAutoresizingMaskIntoConstraints = false
        func nonSafeAreaCondition() -> [NSLayoutConstraint] {
            var constraints: [NSLayoutConstraint] = []
            if edges.contains(.left) { constraints.append(leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left)) }
            if edges.contains(.top) { constraints.append(topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top)) }
            if edges.contains(.right) { constraints.append(trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right)) }
            if edges.contains(.bottom) { constraints.append(bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom)) }
            NSLayoutConstraint.activate(constraints)
            return constraints
        }
        guard useSafeArea else { return nonSafeAreaCondition() }
        if #available(iOS 11.0, *) {
            var constraints: [NSLayoutConstraint] = []
            if edges.contains(.left) { constraints.append(leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: insets.left)) }
            if edges.contains(.top) { constraints.append(topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: insets.top)) }
            if edges.contains(.right) { constraints.append(trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -insets.right)) }
            if edges.contains(.bottom) { constraints.append(bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -insets.bottom)) }
            NSLayoutConstraint.activate(constraints)
            return constraints
        } else {
            return nonSafeAreaCondition()
        }
    }

    func addSubview(_ subview: UIView, constrainedToCenterWithOffset offset: CGPoint) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        let constraints: [NSLayoutConstraint] = [
            subview.centerXAnchor.constraint(equalTo: centerXAnchor, constant: offset.x),
            subview.centerYAnchor.constraint(equalTo: centerYAnchor, constant: offset.y),
        ]
        NSLayoutConstraint.activate(constraints)
    }
}

public extension UIView {
    @discardableResult func constrainSize(to size: CGSize, priority: UILayoutPriority = .required) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        let constraints = [widthAnchor.constraint(equalToConstant: size.width).with(priority: priority), heightAnchor.constraint(equalToConstant: size.height).with(priority: priority)]
        NSLayoutConstraint.activate(constraints)
        return constraints
    }

    @discardableResult func constrainWidth(to width: CGFloat, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let constraint = widthAnchor.constraint(equalToConstant: width).with(priority: priority)
        constraint.isActive = true
        return constraint
    }

    @discardableResult func constrainHeight(to height: CGFloat, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let constraint = heightAnchor.constraint(equalToConstant: height).with(priority: priority)
        constraint.isActive = true
        return constraint
    }
}

// MARK: - UIView Extensions
public extension UIView {
    convenience init(backgroundColor: UIColor?) {
        self.init()
        self.backgroundColor = backgroundColor
    }

    convenience init(wrapping subview: UIView, with insets: UIEdgeInsets = .zero) {
        self.init()
        addSubview(subview, pinningEdges: .all, withInsets: insets)
    }

    var parentViewController: UIViewController? {
        weak var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController { return viewController }
        }
        return nil
    }

    func copiedView<T: UIView>() -> T {
        if #available(iOS 11.0, *) {
            return try! NSKeyedUnarchiver.unarchivedObject(ofClass: T.self, from: NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false))!
        } else {
            return NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self)) as! T
        }
    }

    /// Set current view's absolute center to other view's center
    func centerTo(_ view: UIView) {
        frame.origin.x = view.bounds.midX - frame.width / 2
        frame.origin.y = view.bounds.midY - frame.height / 2
    }

    func addGestureRecognizers(_ gestures: [UIGestureRecognizer]) { gestures.forEach { addGestureRecognizer($0) } }
    func addGestureRecognizers(_ gestures: UIGestureRecognizer...) { addGestureRecognizers(gestures) }
}

extension UIView {
    @objc open var borderColor: UIColor? {
        get { return layer.borderColor?.uiColor }
        set { layer.borderColor = newValue?.cgColor }
    }

    @objc open var borderWidth: CGFloat {
        get { return layer.borderWidth }
        set { layer.borderWidth = newValue }
    }
}

// MARK: - UIGestureRecognizer Extensions
extension UIGestureRecognizer {
    /// Disable and re-enable again to cancel the gesture.
    func cancel() { isEnabled = false; isEnabled = true }
}

// MARK: - UIFeedbackGenerator Extensions
@available(iOS 10.0, *)
public extension UIImpactFeedbackGenerator {
    static func fire(_ style: FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

@available(iOS 10.0, *)
public extension UINotificationFeedbackGenerator {
    static func fire(_ type: FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

@available(iOS 10.0, *)
public extension UISelectionFeedbackGenerator {
    static func fire() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

// MARK: - Loop descendant views
public extension UIView {
    /// loop subviews and subviews' subviews
    ///
    /// - parameter closure: subview
    func loopDescendantViews(_ closure: (_ subView: UIView) -> Void) {
        for v in subviews {
            closure(v)
            v.loopDescendantViews(closure)
        }
    }

    /// loop subviews and subviews' subviews
    ///
    /// - parameter nameOfView:   name of subview
    /// - parameter shouldReturn: should return or not when meeting the specific subview
    /// - parameter execute:      subview
    func loopDescendantViews(_ nameOfView: String, shouldReturn: Bool = true, execute: (_ subView: UIView) -> Void) {
        for v in subviews {
            if v.className == nameOfView {
                execute(v)
                if shouldReturn { return }
            }
            v.loopDescendantViews(nameOfView, shouldReturn: shouldReturn, execute: execute)
        }
    }

    /// Get all descendant view with specific name
    ///
    /// - Parameter nameIfView: the view name
    /// - Returns: the results
    func getDescendantViews(_ nameOfView: String) -> [UIView] {
        var views: [UIView] = []
        loopDescendantViews(nameOfView, shouldReturn: false, execute: {
            views.append($0)
        })
        return views
    }
}

// MARK: - HitTest
public extension UIView {
    /// REFERENCE: http://stackoverflow.com/a/34774177/4656574
    /**
     1. We should not send touch events for hidden or transparent views, or views with userInteractionEnabled set to NO;
     2. If touch is inside self, self will be considered as potential result.
     3. Check recursively all subviews for hit. If any, return it.
     4. Else return self or nil depending on result from step 2.

     Note: 'subviews.reversed()' needed to follow view hierarchy from top most to bottom. And check for clipsToBounds to ensure not to test masked subviews.

     Usage:

     Import category in your subclassed view.
     Replace hitTest:withEvent: with this

     override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
     let uiview = super.hitTest(point, withEvent: event)
     print(uiview)
     return overlapHitTest(point, withEvent: event)
     }
     */
    /// Handle issue when you need to receive touch on top most visible view.
    /// - parameter point:       point
    /// - parameter event:       evet
    /// - parameter invisibleOn: If you want hidden view can not be hit, set `invisibleOn` to true
    ///
    /// - returns: UIView
    func overlapHitTest(_ point: CGPoint, with event: UIEvent?, invisibleOn: Bool = false) -> UIView? {
        // 1
        let invisible = (isHidden || alpha == 0) && invisibleOn
        if !isUserInteractionEnabled || invisible { return nil }
        // 2
        var hitView: UIView? = self
        if !self.point(inside: point, with: event) {
            if clipsToBounds {
                return nil
            } else {
                hitView = nil
            }
        }
        // 3
        for subview in subviews.reversed() {
            let insideSubview = convert(point, to: subview)
            if let sview = subview.overlapHitTest(insideSubview, with: event) { return sview }
        }
        return hitView
    }
}

// MARK: - UIWindow Extensions
public extension UIWindow {
    // REFERENCE: http://stackoverflow.com/a/34679549/4656574
    func replaceRootViewController(with replacementController: UIViewController, duration: TimeInterval = 0.4, completion: Closure? = nil) {
        guard let rootVC = rootViewController else { preconditionFailure("rootViewController should not be nil!") }
        let snapshotImageView = UIImageView(image: snapshot)
        self.addSubview(snapshotImageView)
        rootVC.dismiss(animated: false, completion: { [unowned self] in // dismiss all modal view controllers
            self.rootViewController = replacementController
            self.bringSubviewToFront(snapshotImageView)
            UIView.animate(withDuration: duration, animations: {
                snapshotImageView.alpha = 0
            }, completion: { _ in
                snapshotImageView.removeFromSuperview()
                completion?()
            })
        })
    }
}

// MARK: - UIView + Snapshot
public extension UIView {
    var snapshot: UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

    var snapshotData: Data {
        #if os(iOS)
            UIGraphicsBeginImageContext(frame.size)
            layer.render(in: UIGraphicsGetCurrentContext()!)
            let fullScreenshot = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            UIImageWriteToSavedPhotosAlbum(fullScreenshot!, nil, nil, nil)
            return fullScreenshot!.jpegData(compressionQuality: 0.5)!
        #elseif os(OSX)
            let rep: NSBitmapImageRep = self.view.bitmapImageRepForCachingDisplayInRect(self.view.bounds)!
            self.view.cacheDisplayInRect(self.view.bounds, toBitmapImageRep: rep)
            return rep.TIFFRepresentation!
        #endif
    }

    func takeSnapshot(_ frame: CGRect) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: frame.origin.x * -1, y: frame.origin.y * -1)
        guard let currentContext = UIGraphicsGetCurrentContext() else {
            return nil
        }
        layer.render(in: currentContext)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

// MARK: - UIView Corner Radius
public extension UIView {
    func roundCorners(_ corners: CACornerMask = .allCorners, radius: CGFloat, border: (color: UIColor, width: CGFloat)? = nil) {
        clipsToBounds = true
        if #available(iOS 11.0, *) {
            layer.cornerRadius = radius
            layer.maskedCorners = corners
            if let border = border {
                layer.borderColor = border.color.cgColor
                layer.borderWidth = border.width
            }
        } else {
            let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners.toRectCorner, cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            layer.mask = mask
            if let border = border {
                addBorder(mask, borderColor: border.color, borderWidth: border.width)
            }
        }
    }

    private func addBorder(_ mask: CAShapeLayer, borderColor: UIColor, borderWidth: CGFloat) {
        let borderLayer = CAShapeLayer()
        borderLayer.path = mask.path
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.lineWidth = borderWidth
        borderLayer.frame = bounds
        layer.addSublayer(borderLayer)
    }
}

public extension CACornerMask {
    static var topLeft: CACornerMask { return .layerMinXMinYCorner }
    static var topRight: CACornerMask { return .layerMaxXMinYCorner }
    static var bottomLeft: CACornerMask { return .layerMinXMaxYCorner }
    static var bottomRight: CACornerMask { return .layerMaxXMaxYCorner }
    static var allCorners: CACornerMask { return [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner] }
    var toRectCorner: UIRectCorner {
        var corners = UIRectCorner()
        if contains(.topLeft) { corners.insert(.topLeft) }
        if contains(.topRight) { corners.insert(.topRight) }
        if contains(.bottomLeft) { corners.insert(.bottomLeft) }
        if contains(.bottomRight) { corners.insert(.bottomRight) }
        return corners
    }
}

// MARK: - Animations
public extension UIView {
    // MARK: - Rotation Animation
    func rotate(by angle: CGFloat, duration: TimeInterval = 0.25, target: CAAnimationDelegate? = nil) {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.duration = max(0, duration)
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = angle
        rotationAnimation.delegate = target
        rotationAnimation.timingFunction = .init(name: .linear)
        transform = transform.rotated(by: angle)
        layer.add(rotationAnimation, forKey: nil)
    }

    func reverseTransform(duration: TimeInterval) {
        UIView.animate(withDuration: duration) { self.transform = .identity }
    }

    // MARK: - Flash Animation
    func flash(duration: TimeInterval, minAlpha: CGFloat = 0, maxAlpha: CGFloat = 1, repeatCount: Float = .greatestFiniteMagnitude) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = duration
        animation.fromValue = maxAlpha
        animation.toValue = minAlpha
        animation.timingFunction = .init(name: .easeInEaseOut)
        animation.autoreverses = true
        animation.repeatCount = repeatCount
        layer.add(animation, forKey: nil)
    }

    // MARK: - Alpha
    func hide(_ flag: Bool, duration: TimeInterval = 0.25, animated: Bool) {
        guard animated else { isHidden = flag; return }
        let alpha: CGFloat = flag ? 0 : 1
        UIView.animate(withDuration: duration, delay: 0, options: .beginFromCurrentState, animations: {
            self.alpha = alpha
        }) { _ in
            self.isHidden = flag
        }
    }

    func morphingView(duration: TimeInterval = 0.25, toAlpha alpha: CGFloat) {
        UIView.animate(withDuration: duration, delay: 0, options: .beginFromCurrentState, animations: {
            self.alpha = alpha
        }, completion: nil)
    }

    // MARK: - Shake Animation
    func startShaking(frequency: TimeInterval = 0.2, offset: CGFloat = 1.5, direction: ASDirection = .horizontal, repeatCount: Float = .greatestFiniteMagnitude) {
        let animation = CABasicAnimation(keyPath: #keyPath(CALayer.position))
        animation.duration = frequency
        animation.repeatCount = repeatCount
        animation.autoreverses = true
        switch direction {
        case .horizontal:
            animation.fromValue = NSValue(cgPoint: CGPoint(x: center.x - offset, y: center.y))
            animation.toValue = NSValue(cgPoint: CGPoint(x: center.x + offset, y: center.y))
        case .vertical:
            animation.fromValue = NSValue(cgPoint: CGPoint(x: center.x, y: center.y - offset))
            animation.toValue = NSValue(cgPoint: CGPoint(x: center.x, y: center.y + offset))
        }
        layer.add(animation, forKey: #keyPath(CALayer.position))
    }

    func stopShaking() {
        layer.removeAnimation(forKey: #keyPath(CALayer.position))
    }

    func shaking(withDuration duration: TimeInterval, frequency: TimeInterval = 0.2, offset: CGFloat = 1.5, direction: ASDirection = .horizontal, repeartCount: Float = .greatestFiniteMagnitude) {
        startShaking(frequency: frequency, offset: offset, direction: direction, repeatCount: repeartCount)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in self?.stopShaking() }
    }
}

// MARK: - UIButton Extensions
public extension UIButton {
    var image: UIImage? {
        get { return image(for: .normal) }
        set { setImage(newValue, for: .normal) }
    }

    var title: String? {
        get { return title(for: .normal) }
        set { setTitle(newValue, for: .normal) }
    }

    var titleColor: UIColor? {
        get { return titleColor(for: .normal) }
        set { setTitleColor(newValue, for: .normal) }
    }

    var attributedTitle: NSAttributedString? {
        get { return attributedTitle(for: .normal) }
        set { setAttributedTitle(newValue, for: .normal) }
    }
}

// MARK: - Array Extensions
extension Array {
    public func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }

    /// Splits the receiving array into multiple arrays
    ///
    /// - Parameter subCollectionCount: The number of output arrays the receiver should be divided into
    /// - Returns: An array containing `subCollectionCount` arrays. These arrays will be filled round robin style from the receiving array.
    /// So if the receiver was `[0, 1, 2, 3, 4, 5, 6]` the output would be `[[0, 3, 6], [1, 4], [2, 5]]`. If the reviever is empty the output
    /// Will still be `subCollectionCount` arrays, they just all will be empty. This way it's always safe to subscript into the output.
    /// https://stackoverflow.com/a/54636086/4656574
    private func split(subCollectionCount: Int) -> [[Element]] {
        precondition(subCollectionCount > 1, "Can't split the array unless you ask for > 1")
        var output: [[Element]] = []
        (0 ..< subCollectionCount).forEach { outputIndex in
            let indexesToKeep = stride(from: outputIndex, to: count, by: subCollectionCount)
            let subCollection = enumerated().filter { indexesToKeep.contains($0.offset) }.map(\.element)
            output.append(subCollection)
        }
        precondition(output.count == subCollectionCount)
        return output
    }
}

public extension MutableCollection {
    /// REFERENCE: https://stackoverflow.com/a/24029847
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            // Change `Int` in the next line to `IndexDistance` in < Swift 4.1
            let d: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}

public extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}

public extension Collection {
    subscript(ifPresent index: Index) -> Element? {
        return (index >= startIndex && index < endIndex) ? self[index] : nil
    }
}

public extension Collection where Element: Numeric {
    var sum: Element { return reduce(0, +) }
}

public extension Collection where Element: BinaryInteger {
    /// Returns `0` if it's empty
    var average: Double { return isEmpty ? 0 : Double(sum) / Double(count) }
}

public extension Collection where Element: BinaryFloatingPoint {
    /// Returns `0` if it's empty
    var average: Element { return isEmpty ? 0 : sum / Element(count) }
}

public extension Array {
    func find(_ includedElement: (Element) -> Bool) -> Int? {
        for (idx, element) in enumerated() {
            if includedElement(element) {
                return idx
            }
        }
        return nil
    }

    @available(iOS, deprecated, message: "prefer: 'array[ifPresent: index]'")
    /// Find the element at the specific index
    /// No need to use this to find the first element, just use `aArray.first`
    func object(_ atIndex: Int) -> Element? {
        guard atIndex >= startIndex && atIndex < endIndex else { return nil }
        return self[atIndex]
    }

    mutating func append(newElements: [Element]) {
        self = (self + newElements)
    }
}

public extension Array where Element: Equatable {
    var originalOrderUnique: Array {
        return reduce([]) { $0.contains($1) ? $0 : $0 + [$1] }
    }
}

public extension Sequence where Iterator.Element: Hashable {
    var unique: [Iterator.Element] {
        return Array(Set(self))
    }
}

public extension Sequence {
    // REFERENCE: https://stackoverflow.com/questions/31220002/how-to-group-by-the-elements-of-an-array-in-swift
    @available(swift, deprecated: 4.0, message: "Please use 'Dictionary(grouping:, by:)'")
    func group<U: Hashable>(by key: (Iterator.Element) -> U) -> [U: [Iterator.Element]] {
        var categories: [U: [Iterator.Element]] = [:]
        for element in self {
            let key = key(element)
            if case nil = categories[key]?.append(element) { categories[key] = [element] }
        }
        return categories
    }
}

public extension Array where Element: Equatable {
    /// Move an item to a specific index, if the index doesn't exist, will do nothing.
    ///
    /// - Parameters:
    ///   - item: The item needs to move.
    ///   - newIndex: The destination index.
    mutating func move(item: Element, to newIndex: Index) {
        guard let index = firstIndex(of: item) else { return }
        move(at: index, to: newIndex)
    }

    /// Bring the specific item to the first index, if the item doesn't exist, will do nothing.
    ///
    /// - Parameter item: The item needs to move.
    mutating func bringToFront(item: Element) {
        move(item: item, to: 0)
    }

    /// Send the specific item to the last index, if the item doesn't exist, will do nothing.
    ///
    /// - Parameter item: The item needs to move.
    mutating func sendToBack(item: Element) {
        move(item: item, to: endIndex - 1)
    }
}

public extension Array {
    /// - Note: You'll need to guarantee the indexes are exist, that means index should not be out of range.
    mutating func move(at index: Index, to newIndex: Index) {
        insert(remove(at: index), at: newIndex)
    }
}

// MARK: - Clamp number
public extension Comparable {
    func clamped(lower: Self) -> Self { return self < lower ? lower : self }
    func clamped(upper: Self) -> Self { return self > upper ? upper : self }
    func clamped(lower: Self, upper: Self) -> Self { return min(max(self, lower), upper) }
    func clamped(_ value1: Self, _ value2: Self) -> Self { return min(max(self, min(value1, value2)), max(value1, value2)) }
}

// MARK: - Reutrn bool value
public extension Numeric { var bool: Bool { return self != .zero } }
public extension Bool { init<T: Numeric>(_ numeric: T) { self.init(numeric != .zero) } }
// MARK: - Custom operators
/// "augus" == ("augus", "n") is true
public func == (lhs: String?, rhs: (String, String)) -> Bool { return lhs == rhs.0 || lhs == rhs.1 }
/// "augus" ~= ("Augus", "n") is true
public func ~= (lhs: String?, rhs: (String, String)) -> Bool { return lhs ~= rhs.0 || lhs ~= rhs.1 }
/// "augus" ~= "Augus" is true
public func ~= (lhs: String?, rhs: String?) -> Bool { if lhs == rhs { return true }; return lhs?.lowercased() == rhs?.lowercased() }
/// "123" == 123 is true
public func == (lhs: String, rhs: Int) -> Bool { return Int(lhs) == rhs }
/// 123 == "123" is true
public func == (lhs: Int, rhs: String) -> Bool { return lhs == Int(rhs) }
/// 1 ~= [2, 3, 1] is true
public func ~= <T: Comparable>(lhs: T?, rhs: [T]) -> Bool { return lhs != nil ? rhs.contains(lhs!) : false }
/// Dictionary operator
public func += <K, V>(lhs: inout [K: V], rhs: [K: V]) { for (k, v) in rhs { lhs[k] = v } }
/// Dictionary operator
public func + <K, V>(_ lhs: [K: V], _ rhs: [K: V]) -> [K: V] { var temp = lhs; temp += rhs; return temp }

public func * (_ size: CGSize, _ ratio: CGFloat) -> CGSize { return CGSize(width: size.width * ratio, height: size.height * ratio) }
public func / (_ size: CGSize, _ ratio: CGFloat) -> CGSize { return size * (1 / ratio) }
public func + (_ lhs: CGSize, _ rhs: CGSize) -> CGSize { return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height) }

postfix operator °
protocol IntegerInitializable: ExpressibleByIntegerLiteral { init(_: Int) }
extension Int: IntegerInitializable {
    public static postfix func ° (lhs: Int) -> CGFloat { return CGFloat(lhs) * .pi / 180 }
    public static postfix func ° (lhs: Int) -> Double { return Double(lhs) * .pi / 180 }
}

// MARK: - Calculations
public protocol Arithmetic: Comparable {
    var int: Int { get }
    var double: Double { get }
    var cgFloat: CGFloat { get }
    init(_ x: Int)
    init(_ x: Double)
    init(_ x: Float)
    init(_ x: CGFloat)
    static prefix func - (x: Self) -> Self
    static func + (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func / (lhs: Self, rhs: Self) -> Self
    static func += (lhs: inout Self, rhs: Self)
    static func -= (lhs: inout Self, rhs: Self)
    static func *= (lhs: inout Self, rhs: Self)
    static func /= (lhs: inout Self, rhs: Self)
}

extension Int: Arithmetic {
    @available(*, deprecated, message: "unnecessary")
    public var int: Int { return self } // `Int()` is unnecessary here, but just for convenience
    public var double: Double { return Double(self) }
    public var cgFloat: CGFloat { return CGFloat(self) }
}

extension Int8: Arithmetic {
    public var int: Int { return Int(self) }
    public var double: Double { return Double(self) }
    public var cgFloat: CGFloat { return CGFloat(self) }
}

extension Int16: Arithmetic {
    public var int: Int { return Int(self) }
    public var double: Double { return Double(self) }
    public var cgFloat: CGFloat { return CGFloat(self) }
}

extension Int32: Arithmetic {
    public var int: Int { return Int(self) }
    public var double: Double { return Double(self) }
    public var cgFloat: CGFloat { return CGFloat(self) }
}

extension Int64: Arithmetic {
    public var int: Int { return Int(self) }
    public var double: Double { return Double(self) }
    public var cgFloat: CGFloat { return CGFloat(self) }
}

extension Float: Arithmetic {
    public var int: Int { return Int(self) }
    public var double: Double { return Double(self) }
    public var cgFloat: CGFloat { return CGFloat(self) }
}

extension Double: Arithmetic {
    public var int: Int { return Int(self) }
    @available(*, deprecated, message: "unnecessary")
    public var double: Double { return self } // `Double()` is unnecessary here, but just for convenience
    public var cgFloat: CGFloat { return CGFloat(self) }
}

extension CGFloat: Arithmetic {
    public var int: Int { return Int(self) }
    public var double: Double { return Double(self) }
    @available(*, deprecated, message: "unnecessary")
    public var cgFloat: CGFloat { return self } // `CGFloat()` is unnecessary here, but just for convenience
}

public func plus<T: Arithmetic>(_ a: T, _ b: T) -> T { return a + b }
public func minus<T: Arithmetic>(_ a: T, _ b: T) -> T { return a - b }
public func multiply<T: Arithmetic>(_ a: T, _ b: T) -> T { return a * b }
public func divide<T: Arithmetic>(_ a: T, _ b: T) -> T { return a / b }

public extension Double {
    func floatingPointValueToInt() -> Int? { return isFinite ? Int(self) : nil }
}

public extension Double {
    func trimmed(decimals count: Int? = nil) -> String {
        if let count = count {
            return String(format: "%.\(count)f", self)
        } else {
            return truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
        }
    }
}

public extension Float {
    func trimmed(decimals count: Int? = nil) -> String {
        if let count = count {
            return String(format: "%.\(count)f", self)
        } else {
            return truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
        }
    }
}

// MARK: - String, NSAttributedString Extensions
public extension String {
    func trimmed() -> String { return trimmingCharacters(in: .whitespacesAndNewlines) }
    @available(swift, obsoleted: 1.0, message: "use 'trimmedNilIfEmpty == nil'")
    var isBlank: Bool { preconditionFailure() }
    var trimmedNilIfEmpty: String? { let t = trimmed(); return t.isEmpty ? nil : t }
    func replacingOccurrences(of: [String], with: String) -> String {
        var str = self
        of.forEach { str = str.replacingOccurrences(of: $0, with: with) }
        return str
    }

    var boolValue: Bool { return NSString(string: self).boolValue }
    var encodeURLComponent: String { return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self }
    var decodeURLComponent: String { return self.components(separatedBy: "+").joined(separator: " ").removingPercentEncoding ?? self }
    var isValidEmail: Bool {
        let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: self)
    }
}

public extension Optional where Wrapped == String {
    var emptyValueIfNil: String {
        return self == nil ? "" : self!
    }
}

public extension String {
    func size(maxWidth: CGFloat = .greatestFiniteMagnitude, maxHeight: CGFloat = .greatestFiniteMagnitude, font: UIFont, ceiled: Bool = false) -> CGSize {
        return size(maxWidth: maxWidth, maxHeight: maxHeight, attributes: [NSAttributedString.Key.font: font], ceiled: ceiled)
    }

    func size(maxWidth: CGFloat = .greatestFiniteMagnitude, maxHeight: CGFloat = .greatestFiniteMagnitude, attributes: [NSAttributedString.Key: Any], ceiled: Bool = false) -> CGSize {
        let size = (self as NSString).boundingRect(with: CGSize(width: maxWidth, height: maxHeight), options: .usesLineFragmentOrigin, attributes: attributes, context: nil).size
        return ceiled ? ceil(size) : size
    }
}

public extension NSAttributedString {
    func size(maxWidth: CGFloat = .greatestFiniteMagnitude, maxHeight: CGFloat = .greatestFiniteMagnitude, ceiled: Bool = false) -> CGSize {
        let size = boundingRect(with: CGSize(width: maxWidth, height: maxHeight), options: .usesLineFragmentOrigin, context: nil).size
        return ceiled ? ceil(size) : size
    }
}

public extension NSAttributedString {
    func trimmedNewlines() -> NSAttributedString {
        var att = self
        while att.string.first == "\n" { att = att.attributedSubstring(from: NSRange(location: 1, length: att.string.count - 1)) }
        while att.string.last == "\n" { att = att.attributedSubstring(from: NSRange(location: 0, length: att.string.count - 1)) }
        return att
    }
}

public extension NSAttributedString {
    convenience init(htmlString: String) throws {
        guard let data = htmlString.data(using: .utf8) else {
            throw NSError(domain: "com.iAugus.error", code: 0, userInfo: nil)
        }
        try self.init(htmlData: data)
    }

    convenience init(htmlData: Data) throws {
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue]
        try self.init(data: htmlData, options: options, documentAttributes: nil)
    }
}

// MARK: - Date Extensions
public extension DateComponents {
    enum Weekday: Int, Hashable, CaseIterable {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    }
}

// MARK: - UIApplication Extensions
public extension UIApplication {
    func initializeInTheFirstTime(key: String? = nil, completion: Closure) {
        let k = (key == nil) ? "ausHasLaunchedHostAppOnce" : key!
        guard !UserDefaults.standard.bool(forKey: k) else { return }
        UserDefaults.standard.set(true, forKey: k)
        completion()
    }
}

// MARK: - - Bundle Extensions
extension Bundle {
    var displayName: String {
        let name = object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        return name ?? (object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String) ?? ""
    }
}

// MARK: - Color Extension
public extension UIColor {
    convenience init(hex: UInt, alpha: CGFloat = 1) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat((hex >> 0) & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    @available(*, deprecated, message: "please use: `init(hex: UInt)`")
    convenience init?(hex: String, alpha: CGFloat = 1.0) {
        let formatted = hex.replacingOccurrences(of: ["0x", "#"], with: "")
        guard let hex = Int(formatted, radix: 16) else { return nil }
        let red = CGFloat(CGFloat((hex & 0xFF0000) >> 16) / 255.0)
        let green = CGFloat(CGFloat((hex & 0x00FF00) >> 8) / 255.0)
        let blue = CGFloat(CGFloat((hex & 0x0000FF) >> 0) / 255.0)
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    func toHexString(uppercased: Bool = false) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb = Int(r * 255) << 16 | Int(g * 255) << 8 | Int(b * 255) << 0
        let result = String(format: "#%06x", rgb)
        return uppercased ? result.uppercased() : result
    }

    var alpha: CGFloat {
        var h = CGFloat(0)
        var s = CGFloat(0)
        var b = CGFloat(0)
        var a = CGFloat(0)
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return a
    }

    var components: UnsafePointer<CGFloat> { return cgColor.__unsafeComponents! }
    var cRed: CGFloat { return components[0] }
    var cGreen: CGFloat { return components[1] }
    var cBlue: CGFloat { return components[2] }
    func alpha(_ alpha: CGFloat) -> UIColor { return withAlphaComponent(alpha) }
    /// Compare two colors
    ///
    /// - Parameters:
    ///   - color: color to be compared
    ///   - tolerance: tolerance (0.0 ~ 1.0)
    /// - Returns: result
    func isEqual(to color: UIColor, withTolerance tolerance: CGFloat = 0.0) -> Bool {
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return abs(r1 - r2) <= tolerance && abs(g1 - g2) <= tolerance && abs(b1 - b2) <= tolerance && abs(a1 - a2) <= tolerance
    }

    class var random: UIColor {
        let randomRed = CGFloat(drand48())
        let randomGreen = CGFloat(drand48())
        let randomBlue = CGFloat(drand48())
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }

    func darker(_ scale: CGFloat) -> UIColor {
        var h = CGFloat(0)
        var s = CGFloat(0)
        var b = CGFloat(0)
        var a = CGFloat(0)
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: b * scale, alpha: a)
    }

    func lighter(_ scale: CGFloat) -> UIColor {
        var h = CGFloat(0)
        var s = CGFloat(0)
        var b = CGFloat(0)
        var a = CGFloat(0)
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s * scale, brightness: b, alpha: a)
    }

    func whiter(_ scale: CGFloat) -> UIColor {
        return UIColor(red: cRed * scale, green: cGreen * scale, blue: cBlue, alpha: 1.0)
    }
}

public extension CGColor {
    var uiColor: UIColor { return UIColor(cgColor: self) }
}

// MARK: - UIAlertController Extension
public extension UIViewController {
    func presentAlert(title: String? = nil, message: String? = nil, actionTitle: String, handler: ((UIAlertAction) -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: actionTitle, style: .default, handler: handler)
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - App
public enum APP {
    public static var version: String? { return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String }
    public static var build: String? { return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String }
    public static func appStoreURL(with id: String) -> URL { return URL(string: appStorePath(with: id))! }
    public static func reviewURL(with id: String) -> URL { return URL(string: appStorePath(with: id) + "?action=write-review")! }
    public static func reviewsPageURL(with id: String) -> URL { return URL(string: "https://itunes.apple.com/app/viewContentsUserReviews?id=\(id)")! }
    private static func appStorePath(with id: String) -> String { return "https://itunes.apple.com/app/id\(id)" }
}

public enum Environment {
    case development, production, sandbox
    public var isRelease: Bool { return self == .production }
    public var isDebug: Bool { return self == .development }
    public static var current: Environment {
        #if DEBUG
            return .development
        #else
            if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" { return .sandbox }
            return .production
        #endif
    }
}

// MARK: - String Extensions
public extension String {
    // MARK: - Localized Strings
    static let yes = NSLocalizedString("YES", comment: "")
    static let no = NSLocalizedString("NO", comment: "")
    static let ok = NSLocalizedString("OK", comment: "")
    static let confirm = NSLocalizedString("Confirm", comment: "")
    static let cancel = NSLocalizedString("Cancel", comment: "")
}

public extension String {
    init<T>(_ instance: T) {
        self.init(describing: instance)
    }

    subscript(i: Int) -> String {
        guard i >= 0 && i < count else { return "" }
        return String(self[index(startIndex, offsetBy: i)])
    }

    subscript(range: Range<Int>) -> String {
        let lowerIndex = index(startIndex, offsetBy: max(0, range.lowerBound), limitedBy: endIndex) ?? endIndex
        return String(self[lowerIndex ..< (index(lowerIndex, offsetBy: range.upperBound - range.lowerBound, limitedBy: endIndex) ?? endIndex)])
    }

    subscript(range: ClosedRange<Int>) -> String {
        let lowerIndex = index(startIndex, offsetBy: max(0, range.lowerBound), limitedBy: endIndex) ?? endIndex
        return String(self[lowerIndex ..< (index(lowerIndex, offsetBy: range.upperBound - range.lowerBound + 1, limitedBy: endIndex) ?? endIndex)])
    }

    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { sInd in
            (range(of: to, range: sInd ..< endIndex)?.lowerBound).map { eInd in
                return String(self[sInd ..< eInd])
            }
        }
    }
}

public extension String {
    /// Returns the actual url if the path is valid, otherwise returns a fake url `URL("https://")!`.
    var url: URL { return URL(string: self) ?? URL(string: "https://")! }
    /// Returns an optional url if the path is valid.
    var optionalURL: URL? { return URL(string: self) }
}

public extension String {
    var validURLs: [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return [] }
        let matches = detector.matches(in: self, options: [], range: NSRange(location: 0, length: count))
        return matches.compactMap { $0.resultType == .link ? $0.url : nil }
    }
}

public extension String {
    func camelCaseToSnakeCase() -> String? {
        return processCamelCase(template: "$1_$2")
    }

    func camelCaseToSentenceCase() -> String? {
        return processCamelCase(template: "$1 $2")
    }

    private func processCamelCase(template: String) -> String? {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let normalPattern = "([a-z0-9])([A-Z])"
        return self.processCamelCaseRegex(pattern: acronymPattern, template: template)?.processCamelCaseRegex(pattern: normalPattern, template: template)
    }

    private func processCamelCaseRegex(pattern: String, template: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: template)
    }
}

public extension StringProtocol {
    func nsRange(of text: String) -> NSRange? { return range(of: text).map { NSRange($0, in: self) } }
}

// MARK: - URL Extensions
public extension URL {
    var lastPathComponentWithoutPathExtension: String {
        return lastPathComponent.replacingOccurrences(of: ".\(pathExtension)", with: "")
    }

    var queryPairs: [String: String] {
        var results = [String: String]()
        let pairs = query?.components(separatedBy: "&") ?? []
        for pair in pairs {
            let kv = pair.components(separatedBy: "=")
            if kv.count > 1 { results.updateValue(kv[1], forKey: kv[0]) }
        }
        return results
    }

    func append(_ queryItem: String, value: String?) -> URL {
        // create query item if value is not nil
        guard let value = value else { return absoluteURL }
        guard var urlComponents = URLComponents(string: absoluteString) else { return absoluteURL }
        // create array of existing query items
        var queryItems: [URLQueryItem] = urlComponents.queryItems ?? []
        let queryItem = URLQueryItem(name: queryItem, value: value)
        // append the new query item in the existing query items array
        queryItems.append(queryItem)
        // append updated query items array in the url component object
        urlComponents.queryItems = queryItems
        // returns the url from new url components
        return urlComponents.url!
    }

    func append(_ params: [String: String?]) -> URL {
        var url = self
        params.forEach { url = url.append($0.key, value: $0.value) }
        return url
    }

    func httpsURL() -> URL {
        guard scheme != "https" else { return self }
        let str = absoluteString.replacingOccurrences(of: "http://", with: "https://")
        return URL(string: str)!
    }
}

// MARK: - Uniform
public extension UIEdgeInsets {
    init(uniform inset: CGFloat) { self.init(top: inset, left: inset, bottom: inset, right: inset) }
    init(uniform inset: Double) { let inset = CGFloat(inset); self.init(top: inset, left: inset, bottom: inset, right: inset) }
    init(uniform inset: Int) { let inset = CGFloat(inset); self.init(top: inset, left: inset, bottom: inset, right: inset) }
    init(horizontal: CGFloat = 0, vertical: CGFloat = 0) { self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal) }
    init(horizontal: Double = 0, vertical: Double = 0) { let h = CGFloat(horizontal); let v = CGFloat(vertical); self.init(top: v, left: h, bottom: v, right: h) }
    init(horizontal: Int = 0, vertical: Int = 0) { let h = CGFloat(horizontal); let v = CGFloat(vertical); self.init(top: v, left: h, bottom: v, right: h) }
    init(top: CGFloat) { self.init(top: top, left: 0, bottom: 0, right: 0) }
    init(left: CGFloat) { self.init(top: 0, left: left, bottom: 0, right: 0) }
    init(bottom: CGFloat) { self.init(top: 0, left: 0, bottom: bottom, right: 0) }
    init(right: CGFloat) { self.init(top: 0, left: 0, bottom: 0, right: right) }
}

public extension CGSize {
    init(uniform value: CGFloat) { self.init(width: value, height: value) }
    init(uniform value: Double) { self.init(width: value, height: value) }
    init(uniform value: Int) { self.init(width: value, height: value) }
}

// MARK: - CoreGraphics
public extension CGRect {
    init(size: CGSize) {
        self.init(origin: .zero, size: size)
    }

    init(center: CGPoint, size: CGSize) {
        let origin = CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2)
        self.init(origin: origin, size: size)
    }

    var center: CGPoint { return CGPoint(x: origin.x + width / 2, y: origin.y + height / 2) }
    var randomPoint: CGPoint {
        let x = CGFloat(arc4random_uniform(UInt32(width))) + origin.x
        let y = CGFloat(arc4random_uniform(UInt32(height))) + origin.y
        return CGPoint(x: x, y: y)
    }
}

public extension CGSize {
    func scale(_ scale: CGFloat) -> CGSize {
        return CGSize(width: width * scale, height: height * scale)
    }
}

public func CGDistance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
    guard p1 != p2 else { return 0 }
    return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2))
}

public func CGTriangleDistance(_ l1: CGFloat, _ l2: CGFloat) -> CGFloat {
    guard l1 != 0 && l2 != 0 else { return 0 }
    return sqrt(pow(l1, 2) + pow(l2, 2))
}

public func CGPointOnLinearLine(withX x: CGFloat, _ began: CGPoint, _ ended: CGPoint) -> CGPoint {
    let k = (ended.y - began.y) / (began.x - began.x)
    let b = (began.y + ended.y - k * (began.x + ended.x)) / 2
    let y = k * x + b
    return CGPoint(x: x, y: y)
}

public func CGPointOnLinearLine(withY y: CGFloat, began: CGPoint, _ ended: CGPoint) -> CGPoint {
    let point = CGPointOnLinearLine(withX: y, began, ended)
    return CGPoint(x: point.y, y: point.x)
}

public func CGPointsOnOneLine(_ point1: CGPoint, _ point2: CGPoint, _ point3: CGPoint) -> Bool {
    let k = (point2.y - point1.y) / (point2.x - point1.x)
    let b = (point1.y + point2.y - k * (point1.x + point2.x)) / 2
    return point3.y == k * point3.x + b
}

public func CGPointsOnOneLine(_ points: CGPoint...) -> Bool { return CGPointsOnOneLine(points) }
public func CGPointsOnOneLine(_ points: [CGPoint]) -> Bool {
    guard points.count > 2 else { return true }
    guard points.count > 3 else { return CGPointsOnOneLine(points[0], points[1], points[2]) }
    for point in points[3 ..< points.count] { if !CGPointsOnOneLine(point, points[0], points[1]) { return false } }
    return true
}

public func CGPointNotIn(rects: CGRect..., point: CGPoint) -> Bool { return CGPointNotIn(rects: rects, point: point) }
public func CGPointNotIn(rects: [CGRect], point: CGPoint) -> Bool {
    for rect in rects { if rect.contains(point) { return false } }
    return true
}

public func CGPointInsideRing(point: CGPoint, center: CGPoint, firstRadius: CGFloat, secondRadius: CGFloat) -> Bool {
    let area = touchArea(point, center: center)
    let smaller = sumOfSquares(min(firstRadius, secondRadius))
    let bigger = sumOfSquares(max(firstRadius, secondRadius))
    return area >= smaller && area <= bigger
}

public func CGPointInsideCircle(point: CGPoint, center: CGPoint, radius: CGFloat) -> Bool {
    let area = touchArea(point, center: center)
    return area <= sumOfSquares(radius)
}

private func touchArea(_ point: CGPoint, center: CGPoint) -> Double {
    return sumOfSquares(point.x - center.x) + sumOfSquares(point.y - center.y)
}

private func sumOfSquares(_ x: CGFloat) -> Double { return pow(Double(x), 2) }

// MARK: - UserDefaults Extensions
public extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if value(forKey: key) == nil { set(defaultValue, forKey: key) }
        return bool(forKey: key)
    }

    func integer(forKey key: String, defaultValue: Int) -> Int {
        if value(forKey: key) == nil { set(defaultValue, forKey: key) }
        return integer(forKey: key)
    }

    func string(forKey key: String, defaultValue: String) -> String {
        if value(forKey: key) == nil { set(defaultValue, forKey: key) }
        return string(forKey: key) ?? defaultValue
    }

    func double(forKey key: String, defaultValue: Double) -> Double {
        if value(forKey: key) == nil { set(defaultValue, forKey: key) }
        return double(forKey: key)
    }

    func object(forKey key: String, defaultValue: AnyObject) -> Any? {
        if object(forKey: key) == nil { set(defaultValue, forKey: key) }
        return object(forKey: key)
    }

    func color(forKey key: String) -> UIColor? {
        return given(data(forKey: key)) { data in
            if #available(iOS 11.0, *) {
                return try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)
            } else {
                return NSKeyedUnarchiver.unarchiveObject(with: data) as? UIColor
            }
        }
    }

    func setColor(_ color: UIColor?, forKey key: String) {
        let data: Data? = given(color) { color in
            if #available(iOS 11.0, *) {
                return try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
            } else {
                return NSKeyedArchiver.archivedData(withRootObject: color)
            }
        }
        set(data, forKey: key)
    }

    @available(swift, deprecated: 11.0, obsoleted: 50.0, message: "Please take advantage of 'Codable'")
    func setArchivedData(_ object: Any?, forKey key: String) {
        given(object) {
            let data = NSKeyedArchiver.archivedData(withRootObject: $0)
            set(data, forKey: key)
        }
    }

    @available(swift, deprecated: 11.0, obsoleted: 50.0, message: "Please take advantage of 'Codable'")
    func unarchiveObjectWithData(forKey key: String) -> Any? {
        guard let object = object(forKey: key) else { return nil }
        guard let data = object as? Data else { return nil }
        return NSKeyedUnarchiver.unarchiveObject(with: data)
    }
}

// MARK: - UIImageView EXtensions
public extension UIImageView {
    var renderingMode: UIImage.RenderingMode {
        get { return image?.renderingMode ?? .automatic }
        set { if let img = image { image = img.withRenderingMode(newValue) } }
    }

    func setImageWithFadeAnimation(_ image: UIImage?, duration: TimeInterval = 1.0) {
        guard let image = image else { return }
        let transition = CATransition()
        transition.duration = duration
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = CATransitionType.fade
        layer.add(transition, forKey: nil)
        self.image = image
    }

    @IBInspectable var ignoresInvertColors: Bool {
        get { if #available(iOS 11.0, *) { return accessibilityIgnoresInvertColors } else { return false } }
        set { if #available(iOS 11.0, *) { accessibilityIgnoresInvertColors = newValue } }
    }
}

public extension UIImage {
    convenience init?(cgImage: CGImage?) {
        guard let cgImage = cgImage else { return nil }
        self.init(cgImage: cgImage)
    }

    convenience init?(view: UIView?) {
        guard let view = view else { return nil }
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: image?.cgImage)
    }

    convenience init?(frame: CGRect, color: UIColor?, isOpaque: Bool = true, scale: CGFloat = 0) {
        guard let color = color else { return nil }
        UIGraphicsBeginImageContextWithOptions(frame.size, isOpaque, scale)
        color.setFill()
        UIRectFill(frame)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: image?.cgImage)
    }

    @available(iOS 13.0, *)
    convenience init?(systemName: String, pointSize: CGFloat, weight: UIImage.SymbolWeight = .regular) {
        self.init(systemName: systemName, withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight))
    }

    var originalRender: UIImage { return withRenderingMode(.alwaysOriginal) }
    var templateRender: UIImage { return withRenderingMode(.alwaysTemplate) }

    func roundedScaledToSize(_ size: CGSize) -> UIImage { return (resize(to: size) ?? self).rounded() }

    func rounded(radius: CGFloat? = nil) -> UIImage {
        let imageLayer = CALayer()
        imageLayer.frame = CGRect(origin: .zero, size: size)
        imageLayer.contents = cgImage
        imageLayer.masksToBounds = true
        let radius = radius ?? min(size.width, size.height) / 2
        imageLayer.cornerRadius = radius
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        imageLayer.render(in: UIGraphicsGetCurrentContext()!)
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return roundedImage ?? UIImage()
    }
}

// MARK: - - UIImage + Resize
public extension UIImage {
    /// Returns scaled image, returns nil if failed.
    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }

    func scaledToWidth(_ width: CGFloat) -> UIImage? {
        guard width < size.width else { return self }
        let scale = width / size.width
        let newSize = CGSize(width: width, height: size.height * scale)
        return resize(to: newSize)
    }

    func scaledToHeight(_ height: CGFloat) -> UIImage? {
        guard height < size.height else { return self }
        let scale = height / size.height
        let newSize = CGSize(width: size.width * scale, height: height)
        return resize(to: newSize)
    }
}

extension UIImage {
    public var rotatedImageByOrientation: UIImage {
        // return if the orientation is already correct
        guard imageOrientation != .up else { return self }
        let transform = calculatedAffineTransform
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        guard let cgImage = self.cgImage, let colorSpace = cgImage.colorSpace else { return self }
        let width = size.width
        let height = size.height
        guard let ctx = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: cgImage.bitmapInfo.rawValue) else { return self }
        ctx.concatenate(transform)
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: height, height: width))
        default:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        // And now we just create a new UIImage from the drawing context
        if let cgImage = ctx.makeImage() {
            return UIImage(cgImage: cgImage)
        } else {
            return self
        }
    }

    private var calculatedAffineTransform: CGAffineTransform {
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform = CGAffineTransform.identity
        let width = size.width
        let height = size.height
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: width, y: height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: height)
            transform = transform.rotated(by: .pi / -2)
        default:
            break
        }
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        return transform
    }
}

public extension UIImage {
    func tintedImage(with color: UIColor) -> UIImage? {
        guard let maskImage = self.cgImage else { return nil }
        let width = self.size.width
        let height = self.size.height
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let bitmapContext = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        else { return nil }
        bitmapContext.clip(to: bounds, mask: maskImage)
        bitmapContext.setFillColor(color.cgColor)
        bitmapContext.fill(bounds)
        guard let cImage = bitmapContext.makeImage() else { return nil }
        let coloredImage = UIImage(cgImage: cImage)
        return coloredImage
    }

    /// Invert the color of the image, then return the new image
    /// REFERENCE: http://stackoverflow.com/a/38835122/4656574
    /// - parameter cgResult: whether or not to convert to cgImgae, default is false
    /// - returns: inverted image, nil if failed
    func inversedImage(cgResult: Bool = false) -> UIImage? {
        let coreImage = UIKit.CIImage(image: self)
        guard let filter = CIFilter(name: "CIColorInvert") else { return nil }
        filter.setValue(coreImage, forKey: kCIInputImageKey)
        guard let result = filter.value(forKey: kCIOutputImageKey) as? UIKit.CIImage else { return nil }
        guard cgResult else { return UIImage(ciImage: result) }
        guard let cgImage = CIContext(options: nil).createCGImage(result, from: result.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - - UITextView
public extension UITextView {
    func exclude(rects: [CGRect]) {
        textContainer.exclusionPaths = rects.map { UIBezierPath(rect: $0) }
    }
}

// MARK: - Selector Extensions
public extension Selector {
    static let dismissAnimated = #selector(UIViewController.dismissAnimated)
    static let dismissWithoutAnimation = #selector(UIViewController.dismissWithoutAnimation)
    static let popViewControllerAnimated = #selector(UIViewController.popViewControllerAnimated)
    static let popViewControllerWithoutAnimation = #selector(UIViewController.popViewControllerWithoutAnimation)
}

// MARK: - - Dismiss view controller
public extension UIViewController {
    @objc func dismissAnimated() { dismiss(animated: true, completion: nil) }
    @objc func dismissWithoutAnimation() { dismiss(animated: false, completion: nil) }
    @objc func popViewControllerAnimated() { _ = navigationController?.popViewController(animated: true) }
    @objc func popViewControllerWithoutAnimation() { _ = navigationController?.popViewController(animated: false) }
    func presentViewControllerWithPushAnimation(destinationVC: UIViewController, duration: TimeInterval = 0.25) {
        let transition = CATransition()
        transition.duration = duration
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = .push
        transition.subtype = .fromRight
        transition.isRemovedOnCompletion = true
        view.window?.layer.add(transition, forKey: nil)
        present(destinationVC, animated: false, completion: nil)
    }

    func dismissViewControllerWithPopAnimation(duration: TimeInterval = 0.25) {
        let transition = CATransition()
        transition.duration = duration
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = .push
        transition.subtype = .fromLeft
        transition.isRemovedOnCompletion = true
        view.window?.layer.add(transition, forKey: nil)
        dismiss(animated: false, completion: nil)
    }

    func present(_ vc: UIViewController) {
        present(vc, animated: true, completion: nil)
    }

    func push(_ vc: UIViewController) {
        navigationController?.pushViewController(vc, animated: true)
    }

    func show(_ vc: UIViewController) {
        show(vc, sender: nil)
    }
}

// MARK: - UIViewController Extensions
public extension UIViewController {
    /// Load view from nib. Note: File's Owner must be equal to the class name.
    static func loadFromNib() -> Self { return loadFromNib(self) }
    private static func loadFromNib<T: UIViewController>(_ type: T.Type) -> T {
        return Bundle.main.loadNibNamed(String(describing: type), owner: self, options: nil)![0] as! T
    }

    /// Check whether this view controller is presented or not.
    var isModal: Bool {
        return presentingViewController != nil || navigationController?.presentingViewController?.presentedViewController == navigationController || tabBarController?.presentingViewController is UITabBarController
    }
}

// MARK: - Top Most View Controller
/// Description: the toppest view controller of presenting view controller
/// How to use:  UIApplication.shared.keyWindow?.rootViewController?.topMostViewController
/// Where to use: There are lots of kinds of controllers (UINavigationControllers, UITabbarControllers, UIViewController)
extension UIViewController {
    @objc var topMostViewController: UIViewController? {
        // Handling Modal views
        if let presentedViewController = self.presentedViewController { return presentedViewController.topMostViewController }
        // Handling UIViewController's added as subviews to some other views.
        for view in view.subviews {
            // Key property which most of us are unaware of / rarely use.
            if let subViewController = view.next as? UIViewController { return subViewController.topMostViewController }
        }
        return self
    }
}

extension UITabBarController {
    override var topMostViewController: UIViewController? {
        return selectedViewController?.topMostViewController
    }

    var topVisibleViewController: UIViewController? {
        var top = selectedViewController
        while top?.presentedViewController != nil { top = top?.presentedViewController }
        return top
    }
}

extension UINavigationController {
    override var topMostViewController: UIViewController? {
        return visibleViewController?.topMostViewController
    }
}

// MARK: - UINavigationController Extension
public extension UINavigationController {
    func makeNavBarCompletelyTransparent() {
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
        view.backgroundColor = UIColor.clear
        navigationBar.backgroundColor = UIColor.clear
    }

    @available(iOS, deprecated, message: "please use: `makeNavBarCompletelyTransparent`")
    func completelyTransparentBar() { makeNavBarCompletelyTransparent() }
}

// MARK: - UINavigationBar Extensions
public extension UINavigationBar {
    var lagreTitleHeight: CGFloat {
        let maxSize = subviews.filter { $0.frame.origin.y > 0 }.max { $0.frame.origin.y < $1.frame.origin.y }.map(\.frame.size)
        return maxSize?.height ?? 0
    }

    private enum Association { static var key = 0 }
    /// Supported iOS 12
    var isBottomHairlineHidden: Bool {
        get { return objc_getAssociatedObject(self, &Association.key) as? Bool ?? false }
        set {
            objc_setAssociatedObject(self, &Association.key, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            var imageView: UIImageView?
            func loop() {
                loopDescendantViews { if let iv = $0 as? UIImageView, iv.bounds.height <= 1.0 { imageView = iv; return } }
            }
            loop()
            guard imageView == nil else {
                imageView?.isHidden = newValue
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                loop()
                imageView?.isHidden = newValue
            }
        }
    }
}

// MARK: - UIScrollView Extensions
public extension UIScrollView {
    var isAtBottom: Bool { return contentOffset.y == contentSize.height - bounds.size.height }
    var isOnTop: Bool {
        if #available(iOS 11.0, *) {
            return contentOffset.y == -safeAreaInsets.top
        } else {
            return contentOffset.y == -contentInset.top
        }
    }

    @discardableResult
    func scrollToTop(animated: Bool = true) -> CGPoint {
        let topOffset: CGFloat
        if #available(iOS 11.0, *) {
            topOffset = -safeAreaInsets.top
        } else {
            topOffset = -contentInset.top
        }
        let point = CGPoint(x: 0, y: topOffset)
        setContentOffset(point, animated: animated)
        return point
    }

    @discardableResult
    func scrollToBottom(animated: Bool = true) -> CGPoint {
        let bottomOffset = CGPoint(x: 0, y: contentSize.height - bounds.height)
        setContentOffset(bottomOffset, animated: animated)
        return bottomOffset
    }

    @discardableResult
    func scrollToLeft(animated: Bool = true) -> CGPoint {
        setContentOffset(.zero, animated: animated)
        return .zero
    }

    @discardableResult
    func scrollToRight(animated: Bool = true) -> CGPoint {
        let rightOffset = CGPoint(x: contentSize.width - bounds.width, y: 0)
        setContentOffset(rightOffset, animated: animated)
        return rightOffset
    }
}

public extension UIScrollView {
    var verticalDirection: ASVerticalDirection {
        return panGestureRecognizer.translation(in: self).y < 0 ? .down : .up
    }

    var horizontalDirection: ASHorizontalDirection {
        return panGestureRecognizer.translation(in: self).x < 0 ? .right : .left
    }
}

// MARK: - PathUtilities
public enum PathUtilities {}
public extension PathUtilities {
    static var documentDirectoryPath: String { return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] }
    static var documentDirectoryURL: URL { return URL(fileURLWithPath: documentDirectoryPath, isDirectory: true) }
    static func documentURLForFile(_ named: String) -> URL { return documentDirectoryURL.appendingPathComponent(named) }
    static var libraryDirectoryPath: String { return NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0] }
    static func libraryPathForFile(_ named: String) -> String { return (libraryDirectoryPath as NSString).appendingPathComponent(named) }
    static func documentPath(forResource: String, of type: String) -> URL {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let resourcePath = ((documentsDirectory as NSString).appendingPathComponent(forResource) as NSString).appendingPathExtension(type)
        return URL(fileURLWithPath: resourcePath!)
    }

    static var temporaryDirectoryPath: String { return NSTemporaryDirectory() }
    static var cacheDirectoryPath: String { return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] }
    static func cacheURLForFile(_ named: String) -> URL { return URL(fileURLWithPath: cacheDirectoryPath).appendingPathComponent(named) }
    static func cachePathForFile(_ named: String) -> String { return cacheURLForFile(named).absoluteString }
    static func appGroupDocumentPath(_ appGroupId: String) -> String? {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else { return nil }
        return url.absoluteString.replacingOccurrences(of: "file:", with: "", options: .literal, range: nil)
    }

    /// Create folder if needed
    ///
    /// - Parameter path: the folder path
    /// - Returns: returns true if created, otherwise returns false, if already exists, return nil.
    @discardableResult
    static func createFolder(atPath path: String) -> Bool? {
        guard !FileManager.default.fileExists(atPath: path) else { return nil }
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch { ASError(error.localizedDescription); return false }
    }

    /// Delete the specific file
    ///
    /// - Parameter path: file path to delete
    /// - Returns: returns true if delete successfully, otherwise returns false. If file doesn't exist, returns true.
    @discardableResult
    static func deleteFile(atPath path: String) -> Bool {
        let exists = FileManager.default.fileExists(atPath: path)
        guard exists else { return true }
        do {
            try FileManager.default.removeItem(atPath: path); return true
        } catch {
            ASError(error.localizedDescription); return false
        }
    }

    static func isDirectoryFor(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }

    static func clearTempDirectory() {
        do {
            let paths = (try? FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())) ?? []
            try paths.forEach {
                let path = (NSTemporaryDirectory() as NSString).appendingPathComponent($0)
                try FileManager.default.removeItem(atPath: path)
            }
        } catch { ASError(error) }
    }

    static func fetchRootDirectoryForiCloud(completion: @escaping (URL?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            if !FileManager.default.fileExists(atPath: url.path, isDirectory: nil) {
                do { ASLog("Creating directory...")
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                } catch { ASError(error) }
            }
            DispatchQueue.main.async { completion(url) }
        }
    }
}

// MARK: - Gradient
// REFERENCE: http://stackoverflow.com/a/42020700/4656574
public typealias GradientPoints = (startPoint: CGPoint, endPoint: CGPoint)
public enum GradientOrientation {
    case topRightBottomLeft, topLeftBottomRight, horizontal, vertical
    fileprivate var startPoint: CGPoint { return points.startPoint }
    fileprivate var endPoint: CGPoint { return points.endPoint }
    private var points: GradientPoints {
        switch self {
        case .topRightBottomLeft: return (CGPoint(x: 0.0, y: 1.0), CGPoint(x: 1.0, y: 0.0))
        case .topLeftBottomRight: return (CGPoint(x: 0.0, y: 0.0), CGPoint(x: 1.0, y: 1.0))
        case .horizontal: return (CGPoint(x: 0.0, y: 0.5), CGPoint(x: 1.0, y: 0.5))
        case .vertical: return (CGPoint(x: 0.0, y: 0.0), CGPoint(x: 0.0, y: 1.0))
        }
    }
}

public extension UIView {
    @discardableResult func applyGradient(withColors colors: [UIColor], locations: [NSNumber]? = nil) -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = colors.map(\.cgColor)
        gradient.locations = locations
        layer.insertSublayer(gradient, at: 0)
        return gradient
    }

    @discardableResult func applyGradient(withColors colors: [UIColor], points: GradientPoints) -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = colors.map(\.cgColor)
        gradient.startPoint = points.startPoint
        gradient.endPoint = points.endPoint
        layer.insertSublayer(gradient, at: 0)
        return gradient
    }

    @discardableResult func applyGradient(withColors colors: [UIColor], gradientOrientation orientation: GradientOrientation) -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = colors.map(\.cgColor)
        gradient.startPoint = orientation.startPoint
        gradient.endPoint = orientation.endPoint
        layer.insertSublayer(gradient, at: 0)
        return gradient
    }

    static func gradientLayer(colors: [UIColor], gradientOrientation orientation: GradientOrientation) -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.colors = colors.map(\.cgColor)
        gradient.startPoint = orientation.startPoint
        gradient.endPoint = orientation.endPoint
        return gradient
    }

    static func gradientLayer(colors: [UIColor], points: GradientPoints) -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.colors = colors.map(\.cgColor)
        gradient.startPoint = points.startPoint
        gradient.endPoint = points.endPoint
        return gradient
    }
}

public extension UIStackView {
    convenience init(axis: NSLayoutConstraint.Axis, distribution: UIStackView.Distribution? = nil, alignment: UIStackView.Alignment? = nil, spacing: CGFloat? = nil, arrangedSubviews: [UIView] = []) {
        self.init(arrangedSubviews: arrangedSubviews)
        self.axis = axis
        given(distribution) { self.distribution = $0 }
        given(alignment) { self.alignment = $0 }
        given(spacing) { self.spacing = $0 }
    }
}

public final class ASSpacer: UIView {
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// Create a fixed size view, usually used in stack view.
    /// Set both width and height, so it can be used in both horizontal and vertical stack view.
    /// - Note: While using this initializer, the constraint priority is `999` not `required`.
    init(_ dimension: CGFloat) {
        super.init(frame: .zero)
        constrainSize(to: CGSize(uniform: dimension), priority: .pseudoRequired)
    }

    /// Create a fixed horizontal size view.
    init(horizontal dimension: CGFloat) {
        super.init(frame: .zero)
        constrainWidth(to: dimension)
    }

    /// Create a fixed vertical size view.
    init(vertical dimension: CGFloat) {
        super.init(frame: .zero)
        constrainHeight(to: dimension)
    }
}

// MARK: - UISearchBar Extensions
public extension UISearchBar {
    /// This may be broken in the future iOS release.
    func selectAll() {
        loopDescendantViews("UISearchBarTextField", shouldReturn: false, execute: {
            // Do not use `value(forKey: "searchField") as? UITextField`, may rejected by Apple
            guard let tf = $0 as? UITextField else { return }
            guard tf.responds(to: #selector(selectAll(_:))) else { return }
            // Ensure texts can be selected
            DispatchQueue.main.async { tf.selectAll(nil) }
        })
    }

    func changeTextFieldTintColor(_ color: UIColor) {
        loopDescendantViews {
            if let tf = $0 as? UITextField { tf.tintColor = color; return }
        }
    }

    func customMode(with color: UIColor, placeholder: String?) {
        loopDescendantViews {
            if let tf = $0 as? UITextField {
                tf.tintColor = color; tf.textColor = color
                if let ph = placeholder {
                    let str = NSAttributedString(string: ph, attributes: [NSAttributedString.Key.foregroundColor: color.alpha(0.5)])
                    tf.attributedPlaceholder = str
                }
            }
        }
    }
}

// MARK: - UIRefreshControl Extensions
public extension UIRefreshControl {
    func beginRefreshingManually() {
        guard let scrollView = superview as? UIScrollView else { return }
        let offsetY = scrollView.contentOffset.y - frame.height
        scrollView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: true)
        beginRefreshing()
    }
}

public extension UILabel {
    convenience init(text: String?, style: UIFont.TextStyle? = nil) {
        self.init()
        self.text = text
        guard let style = style else { return }
        font = UIFont.preferredFont(forTextStyle: style)
    }

    var isTruncated: Bool {
        guard let string = text else { return false }
        let size = string.size(maxWidth: bounds.width, font: font, ceiled: false)
        return size.height > bounds.size.height
    }
}

// MARK: - Target Action Handler
public extension Selector {
    /// Selectors can be used as unique `void *` keys, this gets that key.
    var key: UnsafeRawPointer { return unsafeBitCast(self, to: UnsafeRawPointer.self) }
}

public extension NSObject {
    func getAssociatedValue(for key: UnsafeRawPointer) -> Any? {
        return objc_getAssociatedObject(self, key)
    }

    func setAssociatedValue(_ value: Any?, forKey key: UnsafeRawPointer) {
        objc_setAssociatedObject(self, key, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

public class TargetActionHandler: NSObject {
    private let action: Closure
    fileprivate var removeAction: Closure?
    fileprivate init(_ action: @escaping () -> Void) { self.action = action }
    @objc fileprivate func invoke() { action() }
    public func remove() { removeAction?() }
}

public extension UIGestureRecognizer {
    @discardableResult
    func addHandler(_ handler: @escaping Closure) -> TargetActionHandler {
        let target = TargetActionHandler(handler)
        target.removeAction = { [weak self, unowned target] in self?.removeTarget(target, action: nil) }
        addTarget(target, action: #selector(TargetActionHandler.invoke))
        setAssociatedValue(target, forKey: unsafeBitCast(target, to: UnsafeRawPointer.self)) // Retain for lifetime of receiver
        return target
    }

//    public convenience init(handler: @escaping Closure) {
//        self.init()
//        self.addHandler(handler)
//    }
}

public extension UIControl {
    @discardableResult
    func addHandler(for events: UIControl.Event, handler: @escaping Closure) -> TargetActionHandler {
        let target = TargetActionHandler(handler)
        target.removeAction = { [weak self, unowned target] in self?.removeTarget(target, action: nil, for: .allEvents) }
        addTarget(target, action: #selector(TargetActionHandler.invoke), for: events)
        setAssociatedValue(target, forKey: unsafeBitCast(target, to: UnsafeRawPointer.self)) // Retain for lifetime of receiver
        return target
    }
}

public extension UIButton {
    @discardableResult
    func addTapHandler(_ handler: @escaping Closure) -> TargetActionHandler {
        return addHandler(for: .touchUpInside, handler: handler)
    }
}

public extension UIBarButtonItem {
    convenience init(title: String, style: UIBarButtonItem.Style = .plain, handler: @escaping Closure) {
        let target = TargetActionHandler(handler)
        self.init(title: title, style: style, target: target, action: #selector(TargetActionHandler.invoke))
        setAssociatedValue(target, forKey: unsafeBitCast(target, to: UnsafeRawPointer.self)) // Retain for lifetime of receiver
    }

    convenience init(image: UIImage?, style: UIBarButtonItem.Style = .plain, handler: @escaping Closure) {
        let target = TargetActionHandler(handler)
        self.init(image: image, style: style, target: target, action: #selector(TargetActionHandler.invoke))
        setAssociatedValue(target, forKey: unsafeBitCast(target, to: UnsafeRawPointer.self)) // Retain for lifetime of receiver
    }

    convenience init(barButtonSystemItem systemItem: UIBarButtonItem.SystemItem, handler: @escaping Closure) {
        let target = TargetActionHandler(handler)
        self.init(barButtonSystemItem: systemItem, target: target, action: #selector(TargetActionHandler.invoke))
        setAssociatedValue(target, forKey: unsafeBitCast(target, to: UnsafePointer.self))
    }
}

// MARK: - ASTextField
/// An UITextField with custom insets.
public class ASTextField: UITextField {
    public var insets: UIEdgeInsets = .zero { didSet { setNeedsDisplay() } }
    public convenience init(insets: UIEdgeInsets, textAlignment: NSTextAlignment = .left) {
        self.init()
        self.textAlignment = textAlignment
        self.insets = insets
    }

    override public func textRect(forBounds bounds: CGRect) -> CGRect {
        return super.textRect(forBounds: bounds).inset(by: insets)
    }

    override public func editingRect(forBounds bounds: CGRect) -> CGRect {
        return super.editingRect(forBounds: bounds).inset(by: insets)
    }
}

// MARK: - ASLabel
/// An UILabel with custom insets.
public class ASLabel: UILabel {
    public var insets: UIEdgeInsets = .zero { didSet { setNeedsDisplay() } }
    public convenience init(padding: UIEdgeInsets) {
        self.init()
        self.insets = padding
    }

    override public func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override public var intrinsicContentSize: CGSize {
        let superContentSize = super.intrinsicContentSize
        let width = superContentSize.width + insets.left + insets.right
        let heigth = superContentSize.height + insets.top + insets.bottom
        return CGSize(width: width, height: heigth)
    }

    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        let superSizeThatFits = super.sizeThatFits(size)
        let width = superSizeThatFits.width + insets.left + insets.right
        let heigth = superSizeThatFits.height + insets.top + insets.bottom
        return CGSize(width: width, height: heigth)
    }
}

// MARK: - ASButton
/// A UIButton with custom clickable area.
public class ASButton: UIButton {
    public var clickableArea: CGSize = .zero
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard clickableArea.width > .zero else { return super.hitTest(point, with: event) }
        let minimalWidth = clickableArea.width, minimalHeight = clickableArea.height
        let buttonWidth = frame.width, buttonHeight = frame.height
        let widthToAdd = (minimalWidth - buttonWidth > 0) ? minimalWidth - buttonWidth : 0
        let heightToAdd = (minimalHeight - buttonHeight > 0) ? minimalWidth - buttonHeight : 0
        let largerFrame = CGRect(x: -widthToAdd / 2, y: -heightToAdd / 2, width: buttonWidth + widthToAdd, height: buttonHeight + heightToAdd)
        return largerFrame.contains(point) ? self : nil
    }
}

// MARK: - - Swizzler
public enum Swizzler {
    static func swizzleMethods(for cls: AnyClass?, originalSelector: Selector, swizzledSelector: Selector) {
        guard let originalMethod = class_getInstanceMethod(cls, originalSelector),
              let swizzledMethod = class_getInstanceMethod(cls, swizzledSelector)
        else {
            ASWarn("Can't find the selector to swizzle!")
            return
        }
        let didAddMethod = class_addMethod(cls, originalSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        if didAddMethod {
            class_replaceMethod(cls.self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

// MARK: - Log
#if DEBUG
    public func ASLog(_ message: Any?, filename: NSString = #file, function: String = #function, line: Int = #line) {
        NSLog("[\(filename.lastPathComponent):\(line)] \(function) - \(String(describing: message))")
    }

    public func ASWarn(_ message: Any?, filename: NSString = #file, function: String = #function, line: Int = #line) {
        NSLog("[\(filename.lastPathComponent):\(line)] \(function) - ⚠️ Warning: \(String(describing: message))")
    }

    public func ASError(_ message: Any?, filename: NSString = #file, function: String = #function, line: Int = #line) {
        NSLog("[\(filename.lastPathComponent):\(line)] \(function) - ❌ Error: \(String(describing: message))")
    }

    public func ASPrint(_ any: Any?) { print(any ?? "nil") }
    public func ASPrint(_ any: Any?, prefix: String = "", suffix: String = "") { print(prefix + String(describing: any) + suffix) }

    // MARK: - Depracated
    @available(iOS, deprecated, message: "please use: ASLog")
    public func asLog(_ message: Any?, filename: NSString = #file, function: String = #function, line: Int = #line) {
        NSLog("[\(filename.lastPathComponent):\(line)] \(function) - \(String(describing: message))")
    }

    @available(iOS, deprecated, message: "please use: ASPrint")
    public func asPrint(_ any: Any?) { print(any ?? "nil") }
    @available(iOS, deprecated, message: "please use: ASPrint")
    public func asPrint(_ any: Any?, prefix: String = "", suffix: String = "") { print(prefix + String(describing: any) + suffix) }
#else
    public func ASLog(_ message: Any?, filename: NSString = #file, function: String = #function, line: Int = #line) {}
    public func ASWarn(_ message: Any?, filename: NSString = #file, function: String = #function, line: Int = #line) {}
    public func ASError(_ message: Any?, filename: NSString = #file, function: String = #function, line: Int = #line) {}
    public func ASPrint(_ any: Any?) {}
    public func ASPrint(_ any: Any?, prefix: String = "", suffix: String = "") {}

    // MARK: - Depracated
    @available(iOS, deprecated, message: "please use: ASLog")
    public func asLog(_ message: Any?, filename: NSString = #file, function: String = #function, line: Int = #line) {}
    @available(iOS, deprecated, message: "please use: ASPrint")
    public func asPrint(_ any: Any?) {}
    @available(iOS, deprecated, message: "please use: ASPrint")
    public func asPrint(_ any: Any?, prefix: String = "", suffix: String = "") {}
#endif

// MARK: - Deprecated
public extension UIViewController {
    @available(iOS, deprecated, message: "Will be removed!")
    func configureScreenEdgeDismissGesture(_ edges: UIRectEdge = .left, animated: Bool = true, alsoForPad: Bool = true) {
        let action = animated ? #selector(dismissAnimated) : #selector(dismissWithoutAnimation)
        configureScreenEdgeGestures(edges, alsoForPad: alsoForPad, action: action)
    }

    @available(iOS, deprecated, message: "Will be removed!")
    func configureScreenEdgePopGesture(_ edges: UIRectEdge = .left, animated: Bool = true, alsoForPad: Bool = true) {
        let action = animated ? #selector(popViewControllerAnimated) : #selector(popViewControllerWithoutAnimation)
        configureScreenEdgeGestures(edges, alsoForPad: alsoForPad, action: action)
    }

    @available(iOS, deprecated, message: "Will be removed!")
    func configureScreenEdgeGestures(_ edges: UIRectEdge = .left, alsoForPad: Bool = true, action: Selector) {
        if UIDevice.current.userInterfaceIdiom == .pad && !alsoForPad { return }
        view.isUserInteractionEnabled = true
        func left() {
            let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: action)
            gesture.edges = .left
            view.addGestureRecognizer(gesture)
        }
        func right() {
            let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: action)
            gesture.edges = .right
            view.addGestureRecognizer(gesture)
        }
        if edges == .left {
            left()
        } else if edges == .right {
            right()
        } else if edges == [.left, .right] {
            left()
            right()
        }
    }

    /// one of these two parameters must not be nil
    @available(iOS, deprecated, message: "Will be removed!")
    func configureEdgeGestures(leftEdgeAction: Selector? = nil, rightEdgeAction: Selector? = nil, alsoForPad: Bool = true) {
        if let la = leftEdgeAction { configureScreenEdgeGestures(.left, alsoForPad: alsoForPad, action: la) }
        if let ra = rightEdgeAction { configureScreenEdgeGestures(.right, alsoForPad: alsoForPad, action: ra) }
    }
}

public extension UIButton {
    @available(iOS, deprecated, message: "Will be removed!")
    func hideAndDisableButton(_ flag: Bool, duration: TimeInterval = 0.3, animated: Bool = false, closure: Closure? = nil) {
        isEnabled = !flag
        isAccessibilityElement = isEnabled
        guard animated else {
            isHidden = flag
            closure?()
            return
        }
        UIView.animate(withDuration: duration, animations: {
            self.alpha = flag ? 0 : 1
        }) { _ in
            self.isHidden = flag
            self.alpha = 1
            closure?()
        }
    }
}
