//
//  SettingViewController.swift
//  Phonetic
//
//  Created by Augus on 1/29/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

let kUseTones = "kUseTones"
let kFixPolyphonicChar = "kFixPolyphonicChar"
let kUpcasePinyin = "kUpcasePinyin"
let kUseTonesDefaultBool = false
let kFixPolyphonicCharDefaultBool = true
let kUpcasePinyinDefaultBool = false
let kVCWillDisappearNotification = "kVCWillDisappearNotification"
var kShouldRepresentPolyphonicVC = false

final class SettingViewController: UIViewController {
    private let userDefaults = UserDefaults.standard
    private lazy var customBarButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = UIColor.white
        button.setImage(#imageLiteral(resourceName: "additional_settings").templateRender, for: .normal)
        return button
    }()

    @IBOutlet private var polyphonicButton: UIButton!
    @IBOutlet private var useTonesSwitch: UISwitch! { didSet { useTonesSwitch.shouldSwitch(for: kUseTones, default: kUseTonesDefaultBool) } }
    @IBOutlet private var fixPolyphonicCharSwitch: UISwitch! { didSet { fixPolyphonicCharSwitch.shouldSwitch(for: kFixPolyphonicChar, default: kFixPolyphonicCharDefaultBool) } }
    @IBOutlet var upcasePinyinSwitch: UISwitch! { didSet { upcasePinyinSwitch.shouldSwitch(for: kUpcasePinyin, default: kUpcasePinyinDefaultBool) } }

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        useTonesSwitch.onTintColor = .vividColor
        fixPolyphonicCharSwitch.onTintColor = .vividColor
        upcasePinyinSwitch.onTintColor = .vividColor
        polyphonicButton.flash(duration: 1.5, minAlpha: 0.4)
        configureCustomBarButtonItem()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: Notification.Name(rawValue: kVCWillDisappearNotification), object: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "VCPresentPolyphonicVC" else { return }
        guard let destinationVC = segue.destination as? UINavigationController else { return }
        destinationVC.popoverPresentationController?.sourceRect = polyphonicButton.bounds
        destinationVC.popoverPresentationController?.backgroundColor = .phoneticLightGray
    }

    // MARK: Private
    private func configureCustomBarButtonItem() {
        guard let navBar = navigationController?.navigationBar else { return }
        customBarButton.addTarget(self, action: #selector(customBarButtonDidTap), for: .touchUpInside)
        navBar.addSubview(customBarButton, pinningEdges: [.left], withInsets: UIEdgeInsets(uniform: 13))
        customBarButton.constrainSize(to: CGSize(uniform: 25))
        customBarButton.centerYAnchor.constraint(equalTo: navBar.centerYAnchor).isActive = true
        customBarButton.flash(duration: 1.5, minAlpha: 0.4)
    }

    @objc private func customBarButtonDidTap() {
        UIDevice.current.isPad ? presentAdditionalSettingsViewController() : dismiss(animated: true, completion: { [weak self] in
            self?.presentAdditionalSettingsViewController()
        })
    }

    private func presentAdditionalSettingsViewController() {
        let vc = UIStoryboard.Main.instantiateViewController(withIdentifier: "SettingsNavigationController")
        #if targetEnvironment(macCatalyst)
            dismiss(animated: true) {
                UIApplication.shared.topMostViewController?.present(vc)
            }
        #else
            guard let view = AppDelegate.shared.window?.rootViewController?.view else { return }
            if UIDevice.current.isPad {
                vc.modalPresentationStyle = .popover
                vc.popoverPresentationController?.canOverlapSourceViewRect = true
                vc.popoverPresentationController?.sourceView = view
                vc.popoverPresentationController?.sourceRect = CGRect(origin: view.center, size: CGSize.zero)
                vc.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
                vc.popoverPresentationController?.backgroundColor = .phoneticLightGray
            }
            UIApplication.shared.topMostViewController?.present(vc)
        #endif
    }

    // MARK: - Actions of UISwitch
    @IBAction func useTonesSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kUseTones)
    }

    @IBAction func fixPolyphonicCharSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kFixPolyphonicChar)
    }

    @IBAction func upcasePinyinSwitchDidTap(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: kUpcasePinyin)
    }
}

extension SettingViewController {
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        guard UIDevice.current.isPad else { return }
        _ = kShouldRepresentPolyphonicVC ? polyphonicButton?.sendActions(for: .touchUpInside) : ()
    }
}
