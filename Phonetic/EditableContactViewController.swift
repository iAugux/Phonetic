//
//  EditableContactViewController.swift
//  Phonetic
//
//  Created by Augus on 5/22/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Components
import Contacts
import UIKit

protocol EditableContactViewControllerDelegate: AnyObject {
    func contactDidChangeAndSave()
}

final class EditableContactViewController: BaseTableViewController {
    var contact: CNContact?
    weak var delegate: EditableContactViewControllerDelegate?
    private lazy var currentQuickSearchKey: String? = PhoneticContacts.shared.ContactKeyForQuickSearch

    @IBOutlet var phoneticLastNameTextField: HoshiTextField! {
        didSet {
            phoneticLastNameTextField.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            phoneticLastNameTextField.placeholder = NSLocalizedString("Phonetic last name", comment: "")
            guard let name = contact?.phoneticFamilyName else { return }
            phoneticLastNameTextField.text = name
        }
    }

    @IBOutlet var phoneticFirstNameTextField: HoshiTextField! {
        didSet {
            phoneticFirstNameTextField.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            phoneticFirstNameTextField.placeholder = NSLocalizedString("Phonetic first name", comment: "")
            guard let name = contact?.phoneticGivenName else { return }
            phoneticFirstNameTextField.text = name
        }
    }

    @IBOutlet var quickSearchKeyTextField: HoshiTextField! {
        didSet {
            guard let quickSearchKey = currentQuickSearchKey else {
                quickSearchKeyTextField.placeholder = NSLocalizedString("No key for Quick Search", comment: "")
                return
            }
            quickSearchKeyTextField.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            quickSearchKeyTextField.placeholder = NSLocalizedString("Quick search key", comment: "")
            guard let key = contact?.quickSearchBriefName(quickSearchKey) else { return }
            quickSearchKeyTextField.text = key
        }
    }

    @IBOutlet var avatarImageView: UIImageView! {
        didSet {
            avatarImageView.layer.cornerRadius = 55 / 2
            avatarImageView.clipsToBounds = true
            guard let imageData = contact?.thumbnailImageData else { return }
            avatarImageView.image = UIImage(data: imageData)
        }
    }

    @IBOutlet var textFields: [TextFieldEffects]! {
        didSet {
            textFields?.forEach {
                $0.delegate = self
                $0.keyboardType = .asciiCapable
                $0.keyboardAppearance = .dark
                $0.spellCheckingType = .no
                $0.autocorrectionType = .no
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // To ignore the warning, use `scrollViewWillBeginDragging` instead.
        // tableView.keyboardDismissMode = .OnDrag
        tableView.keyboardDismissMode = .interactive
        navigationController?.navigationBar.tintColor = UIColor.white
        let familyName = contact?.familyName ?? ""
        let givenName = contact?.givenName ?? ""
        title = familyName + givenName
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        avatarImageView.resignFirstResponder()
    }

    private func saveContact(_ textField: UITextField) {
        let newText = textField.text?.trimmingCharacters(in: CharacterSet.whitespaces)
        guard let mutableContact = contact?.mutableCopy() as? CNMutableContact else { return }
        if textField == quickSearchKeyTextField && currentQuickSearchKey != nil {
            mutableContact.setValue(newText, forKey: currentQuickSearchKey!)
        } else if textField == phoneticLastNameTextField {
            mutableContact.setValue(newText, forKey: CNContactPhoneticFamilyNameKey)
        } else if textField == phoneticFirstNameTextField {
            mutableContact.setValue(newText, forKey: CNContactPhoneticGivenNameKey)
        }
        PhoneticContacts.shared.saveContact(mutableContact)
        delegate?.contactDidChangeAndSave()
    }
}

// MARK: - UIScrollViewDelegate
extension EditableContactViewController {
    /// Do not inherit anything from it's super in order to disable the animation for the title.
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // resignFirstResponder
        view.endEditing(true)
    }

    /// Do not inherit anything from it's super in order to disable the animation for the title.
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {}
}

// MARK: - UITextFieldDelegate
extension EditableContactViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.selectAll(nil)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        saveContact(textField)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Orientation
extension EditableContactViewController {
    // fix postition error
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        guard UIDevice.current.isPad else { return }
        guard let view = AppDelegate.shared.window?.rootViewController?.view else { return }
        UIApplication.shared.topMostViewController?.popoverPresentationController?.sourceRect = CGRect(origin: view.center, size: CGSize.zero)
    }
}
