//
//  WhitelistViewController.swift
//  Phonetic
//
//  Created by Augus on 5/10/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import ASKit
import Components
import Contacts
import ContactsUI
import UIKit

private func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

var whitelistIdentifiers: NSArray {
    get { return UserDefaults.standard.array(forKey: kWhitelistIdentifiersKey) as NSArray? ?? NSArray() }
    set {
        guard let newId = newValue.firstObject else { return }
        let array = whitelistIdentifiers.mutableCopy() as! NSMutableArray
        array.contains(newId) ? array.remove(newId) : array.add(newId)
        UserDefaults.standard.set(array, forKey: kWhitelistIdentifiersKey)
    }
}

final class WhitelistViewController: BaseTableViewController {
    @IBOutlet private var searchBar: UISearchBar!
    private let DEFAULT_SEARCH_BAR_HEIGHT: CGFloat = 44.0
    private var alertController: UIAlertController!
    private var contacts: [CNContact]?
    private var sortedContacts: NSArray?
    private var filteredContacts: [CNContact]?
    private var whitelistContacts: [CNContact]?
    private var resignFirstResponderGesture: UITapGestureRecognizer?
    private var isSearchTextNotEmpty = false
    private var isSearchBarFirstResponder = false
    private var shouldAlertToRemoveWhitelistsAgain = false

    private lazy var footerView: UILabel = {
        let footer = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        footer.textAlignment = .center
        footer.textColor = UIColor.white
        footer.font = UIFont.systemFont(ofSize: 13)
        return footer
    }()

    private lazy var noContactsInfoLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.gray
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 19)
        label.text = NSLocalizedString("No Contacts", comment: "")
        return label
    }()

    private lazy var segmentedControl: UISegmentedControl = {
        let segmentFirst = NSLocalizedString("All", comment: "")
        let segmentSecond = NSLocalizedString("Whitelists", comment: "")
        return UISegmentedControl(items: [segmentFirst, segmentSecond])
    }()

    private lazy var popoverContentNavigationController: UINavigationController = {
        let popoverContent = UIStoryboard(name: "Whitelist", bundle: nil).instantiateViewController(with: WhitelistInfoPopoverViewController.self)
        let nav = UINavigationController(rootViewController: popoverContent)
        return nav
    }()

    override func loadView() {
        super.loadView()
        title = ""
        tableView.sectionIndexBackgroundColor = UIColor.clear
        tableView.sectionIndexColor = UIColor.white
        tableView.rowHeight = 66
        tableView.tableFooterView = footerView
        navigationController?.view.backgroundColor = UIColor.phoneticLightGray.darker(0.5)
        navigationController?.navigationBar.barTintColor = UIColor.phoneticLightGray.darker(0.5)
        navigationController?.navigationBar.isBottomHairlineHidden = true
        navigationController?.navigationBar.isTranslucent = false
        configureRightBarButtonItemWithInfo()
        // search bar
        searchBar.barStyle = .black
        searchBar.isTranslucent = true
        searchBar.showsCancelButton = false
        searchBar.keyboardAppearance = .dark
        searchBar.enablesReturnKeyAutomatically = true
        searchBar.tintColor = .vividColor
        searchBar.placeholder = NSLocalizedString("Search", comment: "")
        searchBar.delegate = self
        // segmented control
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.tintColor = UIColor.white
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueDidChange(_:)), for: .valueChanged)
        navigationItem.titleView = segmentedControl
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: .close, style: .done, target: self, action: .dismissAnimated)
        ARSLineProgressConfiguration.circleColorOuter = UIColor.iconColorOne.cgColor
        ARSLineProgressConfiguration.circleColorMiddle = UIColor.iconColorFour.cgColor
        ARSLineProgressConfiguration.circleColorInner = UIColor.iconColorThree.cgColor
        !ARSLineProgress.shown ? ARSLineProgress.show() : ()
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            // get all contacts
            self.contacts = PhoneticContacts.shared.allContactsForWhitelist
            guard self.contacts != nil else { return }
            // partition off contacts in order to be filled in different table view sections
            self.sortedContacts = self.partitionObjects(self.contacts! as NSArray,
                                                        collationStringSelector: NSSelectorFromString(CNContactFamilyNameKey),
                                                        spareCollationStringSelector: NSSelectorFromString(CNContactGivenNameKey))
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.updateFooterTitle()
                self.configureNoContactsInfoLabelIfNeeded()
                ARSLineProgress.shown ? ARSLineProgress.hide() : ()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        segmentedControl.selectedSegmentIndex == 1 ? configureRightBarButtonItemWithTrash() : ()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchBar.resignFirstResponder()
        // hide Progress if needed
        ARSLineProgress.shown ? ARSLineProgress.hide() : ()
    }

    private func updateFooterTitle() {
        let results: String
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            if contacts == nil || contacts?.count < 10 {
                results = ""
            } else {
                results = "\(contacts!.count) " + NSLocalizedString("TotalContacts", comment: "")
            }
        case 1:
            if whitelistContacts == nil || whitelistContacts?.count < 10 {
                results = ""
            } else {
                results = "\(whitelistContacts!.count) " + NSLocalizedString("WhitelistTotalContacts", comment: "")
            }
        default:
            return
        }
        footerView.text = results
    }

    private func configureNoContactsInfoLabelIfNeeded() {
        var results = ""
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            if contacts == nil || contacts?.count == 0 {
                results = NSLocalizedString("No Contacts", comment: "")
            } else {
                noContactsInfoLabel.removeFromSuperview()
                return
            }
        case 1:
            if whitelistContacts == nil || whitelistContacts?.count == 0 {
                results = NSLocalizedString("No Whitelists", comment: "")
            } else {
                noContactsInfoLabel.removeFromSuperview()
                return
            }
        default: return
        }
        noContactsInfoLabel.removeFromSuperview()
        guard let view = tableView.backgroundView else { return }
        view.addSubview(noContactsInfoLabel, pinningEdges: [.left, .right], withInsets: UIEdgeInsets(uniform: 32))
        noContactsInfoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        noContactsInfoLabel.text = results
    }

    @objc private func dismiss() {
        inactiveSearchBarResignFirstResponder()
        dismissAnimated()
    }

    @objc private func tableViewDidTap() {
        guard isSearchBarFirstResponder else { return }
        inactiveSearchBarResignFirstResponder()
        tableView.reloadData()
    }

    private func inactiveSearchBarResignFirstResponder(_ reload: Bool = true) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        isSearchTextNotEmpty = false
        isSearchBarFirstResponder = false
        reload ? tableView.reloadData() : ()
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard isSearchBarFirstResponder else { return }
        if tableView.numberOfRows(inSection: 0) == 0 {
            // number of rows is zero, show all contacts
            inactiveSearchBarResignFirstResponder()
        } else {
            // there are results according to the search text, only show results and resign searchBar's first responder
            searchBar.resignFirstResponder()
        }
    }

    private func fetchAndSortWhitelistContacts() {
        // fetch whitelist contacts with identifiers
        whitelistContacts = PhoneticContacts.shared.fetchContactsWithIdentifiers(whitelistIdentifiers)
        guard let QuickSearchKey = PhoneticContacts.shared.ContactKeyForQuickSearch else { return }
        // sort
        whitelistContacts = whitelistContacts?.sorted {
            return $0.quickSearchBriefName(QuickSearchKey) < $1.quickSearchBriefName(QuickSearchKey)
        }
    }

    @objc private func segmentedControlValueDidChange(_ sender: UISegmentedControl) {
        // disable tap on table view gesture if needed
        resignFirstResponderGesture?.isEnabled = sender.selectedSegmentIndex == 0
        inactiveSearchBarResignFirstResponder(false)
        if sender.selectedSegmentIndex == 1 {
            searchBar.frame.size.height = 0
            configureRightBarButtonItemWithTrash()
        } else {
            searchBar.frame.size.height = DEFAULT_SEARCH_BAR_HEIGHT
            configureRightBarButtonItemWithInfo()
        }
        fetchAndSortWhitelistContacts()
        updateFooterTitle()
        configureNoContactsInfoLabelIfNeeded()
        tableView.reloadData()
    }

    private func configureRightBarButtonItemWithTrash() {
        if whitelistIdentifiers.count != 0 {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(alertToRemoveAllWhitelistContacts))
            navigationItem.rightBarButtonItem?.tintColor = UIColor.white
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    private func configureRightBarButtonItemWithInfo() {
        let infoImage: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "info.circle")?.withRenderingMode(.alwaysTemplate)
            } else {
                return UIImage(named: "smaller_info")?.withRenderingMode(.alwaysTemplate)
            }
        }()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: infoImage, style: .plain, target: self, action: #selector(popoverInfoController))
        navigationItem.rightBarButtonItem?.tintColor = .white
    }

    private func scrollWhitelistTableViewToTop(animated: Bool = false) {
        guard tableView.numberOfSections != 0 && tableView.numberOfRows(inSection: 0) != 0 else { return }
        tableView.scrollToTop()
    }

    @objc private func alertToRemoveAllWhitelistContacts() {
        let remove = {
            UserDefaults.standard.set(nil, forKey: kWhitelistIdentifiersKey)
            self.fetchAndSortWhitelistContacts()
            self.updateFooterTitle()
            self.configureNoContactsInfoLabelIfNeeded()
            self.tableView.reloadData()
            self.navigationItem.rightBarButtonItem = nil
        }
        alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let title = NSLocalizedString("Remove All Whitelists", comment: "")
        let removeAction = UIAlertAction(title: title, style: .destructive) { _ in
            remove()
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        alertController.addAction(removeAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: { [weak self] in
            self?.shouldAlertToRemoveWhitelistsAgain = false
        })
    }
}

// MARK: - Sort contacts by alphabet in sections
extension WhitelistViewController {
    private func partitionObjects(_ array: NSArray, collationStringSelector selector: Selector, spareCollationStringSelector spareSelector: Selector) -> NSArray {
        let collation = UILocalizedIndexedCollation.current()
        // section count is taken from sectionTitles and not sectionIndexTitles
        let sectionCount = collation.sectionTitles.count
        let unsortedSections = NSMutableArray(capacity: sectionCount)
        // create an array to hold the data for each section
        for _ in collation.sectionTitles {
            unsortedSections.add(NSMutableArray())
        }
        let numberOfSections = collation.sectionTitles.count
        // put each object into a section
        for object in array {
            // sorted by first selector (e.g: CNContactFamilyNameKey)
            var index = collation.section(for: object, collationStringSelector: selector)
            // if cannot be sorted by first selector, then use spare selector to sort. (e.g: CNContactGivenNameKey)
            if index == numberOfSections - 1 { // "#" section
                index = collation.section(for: object, collationStringSelector: spareSelector)
            }
            (unsortedSections.object(at: index) as AnyObject?)?.add(object)
        }
        let sections = NSMutableArray(capacity: sectionCount)
        // sort each section
        for section in unsortedSections {
            sections.add(collation.sortedArray(from: section as! [AnyObject], collationStringSelector: selector))
        }
        return sections
    }
}

// MARK: - Table view data source
extension WhitelistViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isSearchTextNotEmpty || segmentedControl.selectedSegmentIndex == 1 {
            return 1
        }
        return UILocalizedIndexedCollation.current().sectionTitles.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 1 {
            return whitelistContacts?.count ?? 0
        }
        if isSearchTextNotEmpty {
            return filteredContacts?.count ?? 0
        }
        return (sortedContacts?[section] as? NSArray)?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSearchTextNotEmpty || segmentedControl.selectedSegmentIndex == 1 {
            return nil
        }
        // only show section title while the section contains rows
        guard let count = (sortedContacts?[section] as? NSArray)?.count, count != 0 else { return nil }
        return UILocalizedIndexedCollation.current().sectionTitles[section]
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if isSearchTextNotEmpty || segmentedControl.selectedSegmentIndex == 1 {
            return nil
        }
        return UILocalizedIndexedCollation.current().sectionIndexTitles
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: WhitelistTableViewCell.self, for: indexPath)
        let currentContact: Any? = {
            if segmentedControl.selectedSegmentIndex == 1 {
                return whitelistContacts?[indexPath.row]
            }
            return isSearchTextNotEmpty ? filteredContacts?[indexPath.row] : (sortedContacts?[indexPath.section] as? NSArray)?[indexPath.row]
        }()
        guard let contact = currentContact as? CNContact else { return UITableViewCell() }
        // identifier
        cell.identifier = contact.identifier
        // name
        let family = contact.familyName
        let given = contact.givenName
        let name = isEnglishName([family, given]) ? (given + " " + family) : (family + given)
        cell.nameLabel.text = name
        // phonetic name
        let phoneticFamily = contact.phoneticFamilyName
        let phoneticGiven = contact.phoneticGivenName
        let phoneticName = phoneticFamily + " " + phoneticGiven
        cell.phoneticNameLabel.text = formattedName(phoneticName)
        // avatar
        if let thumbnailImageData = contact.thumbnailImageData, contact.imageDataAvailable {
            cell.avatar.image = UIImage(data: thumbnailImageData)
        } else {
            cell.avatar.image = UIImage(named: "user_male_circle_filled")
        }
        // key for Quick Search
        if let QuickSearchKey = PhoneticContacts.shared.ContactKeyForQuickSearch {
            let briefName = contact.quickSearchBriefName(QuickSearchKey) ?? ""
            cell.briefNameLabel.text = formattedName(briefName)
        } else {
            cell.briefNameLabel.text = " --"
        }
        // switch
        cell.whitelistSwitch.isOn = whitelistIdentifiers.contains(contact.identifier) ? true : false
        return cell
    }
}

// MARK: - Table view delegate
extension WhitelistViewController: CNContactPickerDelegate, CNContactViewControllerDelegate {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // editing contact in EditableContactViewController
        guard segmentedControl.selectedSegmentIndex == 1 else { return }
        guard let cell = tableView.cellForRow(at: indexPath) as? WhitelistTableViewCell else { return }
        cell.setSelected(false, animated: true)
        guard let identifier = cell.identifier else { return }
        let keys = [CNContactViewController.descriptorForRequiredKeys()]
        let contacts = PhoneticContacts.shared.fetchContactWithIdentifiers([identifier], keysToFetch: keys)
        guard let contact = contacts?.first else { return }
        let vc = UIStoryboard(name: "Whitelist", bundle: nil).instantiateViewController(with: EditableContactViewController.self)
        vc.delegate = self
        vc.contact = contact
        navigationController?.pushViewController(vc, animated: true)
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        super.tableView(tableView, willDisplayHeaderView: view, forSection: section)
        (view as! UITableViewHeaderFooterView).contentView.backgroundColor = UIColor.phoneticLightGray.darker(0.5)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
        if segmentedControl.selectedSegmentIndex == 0 {
            cell.selectionStyle = .none
        } else {
            cell.selectionStyle = .default
        }
    }
}

// MARK: - EditableContactViewControllerDelegate
extension WhitelistViewController: EditableContactViewControllerDelegate {
    func contactDidChangeAndSave() {
        fetchAndSortWhitelistContacts()
        tableView.reloadData()
        scrollWhitelistTableViewToTop(animated: true)
    }
}

// MARK: -
extension WhitelistViewController {
    private func formattedName(_ name: String) -> String {
        let name = name.trimmingCharacters(in: NSCharacterSet.whitespaces)
        return name.isEmpty ? " --" : name
    }

    private func isEnglishName(_ names: [String]) -> Bool {
        for name in names {
            let mandarin = PhoneticContacts.shared.antiPhonetic(name)
            if !mandarin { return true }
        }
        return false
    }
}

// MARK: - SearchBar delegate
extension WhitelistViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearchBarFirstResponder = true
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isSearchTextNotEmpty = !searchText.isEmpty
        isSearchTextNotEmpty ? PhoneticContacts.shared.fetchContactsMatchingWith(searchText, closure: {
            self.filteredContacts = $0
            self.tableView.reloadData()
        }) : ()
        tableView.tableFooterView?.isHidden = isSearchTextNotEmpty
    }
}

// MARK: -
extension WhitelistViewController: UIPopoverPresentationControllerDelegate {
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        // fix alertController's position
        alertController?.dismiss(animated: true, completion: {
            self.shouldAlertToRemoveWhitelistsAgain = !UIDevice.current.isPad
        })
    }

    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        // fix alertController's position
        shouldAlertToRemoveWhitelistsAgain ? alertToRemoveAllWhitelistContacts() : ()
        // fix popoverInfoController's position
        /**
         *  Must dismiss it first, because the controller will be behind WhitelistViewController after rotation on iPad or iPhone 6(s) Plus, and it's active.
         *  If you present it again, app will crash due to 'Application tried to present modally an active controller'.
         *  I don't know why it's behind WhitelistViewController, but I guess it's because I popped two times on window (WhitelistViewController + WhitelistInfoPopoverViewController).
         */
        popoverContentNavigationController.dismiss(animated: false, completion: { [weak self] in
            self?.popoverInfoController()
        })

        // fix WhitelistViewController's position on iPad after rotation
        guard UIDevice.current.isPad else { return }
        guard let view = AppDelegate.shared.window?.rootViewController?.view else { return }
        UIApplication.shared.topMostViewController?.popoverPresentationController?.sourceRect = CGRect(origin: view.center, size: CGSize.zero)
    }

    @objc private func popoverInfoController() {
        let nav = popoverContentNavigationController
        nav.navigationBar.isHidden = true
        nav.modalPresentationStyle = .popover
        nav.viewControllers.first?.preferredContentSize = CGSize(width: 220, height: 300)
        nav.popoverPresentationController?.delegate = self
        nav.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        nav.popoverPresentationController?.backgroundColor = .phoneticLightGray
        present(nav, animated: true, completion: nil)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    // MARK: - for iPhone 6(s) Plus
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

    override func overrideTraitCollection(forChild childViewController: UIViewController) -> UITraitCollection? {
        // disable default UITraitCollection, fix size of popover view on iPhone 6(s) Plus.
        return nil
    }
}
