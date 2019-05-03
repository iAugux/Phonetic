//
//  PolyphonicViewController.swift
//  Phonetic
//
//  Created by Augus on 2/23/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

final class PolyphonicViewController: BaseTableViewController {
    private let kEnableAllPolyphonicChars = "kEnableAllPolyphonicCharacters"
    private var names: NSDictionary!
    private var nameSectionTitles: NSArray!
    @IBOutlet private var masterLabel: UILabel!
    @IBOutlet private var headerViewContainer: UIView!
    @IBOutlet private var masterSwitchTrailingConstraint: NSLayoutConstraint!

    @IBOutlet var masterSwitch: UISwitch! { didSet { setMasterLabelText(masterSwitch.isOn) } }

    override func loadView() {
        super.loadView()
        title = NSLocalizedString("Polyphonic Characters", comment: "SettingsNavigationController title - Polyphonic Chararcters")
        tableView.sectionIndexBackgroundColor = UIColor.clear
        tableView.sectionIndexColor = UIColor.white
        masterSwitch.onTintColor = GLOBAL_CUSTOM_COLOR
        masterSwitch.shouldSwitch(for: kEnableAllPolyphonicChars, default: true)
        UIDevice.current.isPad ? masterSwitchTrailingConstraint.constant = 42 : ()
        configureScreenEdgeDismissGesture()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let image = #imageLiteral(resourceName: "close").withRenderingMode(.alwaysTemplate)
        navigationItem.leftBarButtonItem = BarButtonItem(image: image, target: self, action: .dismissAnimated)
        names = [
            "B" : [PolyphonicChar.b1, PolyphonicChar.b2, PolyphonicChar.b3],
            "C" : [PolyphonicChar.c1, PolyphonicChar.c2, PolyphonicChar.c3],
            "D" : [PolyphonicChar.d1],
            "G" : [PolyphonicChar.g1, PolyphonicChar.g2, PolyphonicChar.g3, PolyphonicChar.g4],
            "H" : [PolyphonicChar.h1],
            "J" : [PolyphonicChar.j1, PolyphonicChar.j2],
            "K" : [PolyphonicChar.k1],
            "M" : [PolyphonicChar.m1, PolyphonicChar.m2],
            "N" : [PolyphonicChar.n1],
            "O" : [PolyphonicChar.o1],
            "P" : [PolyphonicChar.p1, PolyphonicChar.p2],
            "Q" : [PolyphonicChar.q1, PolyphonicChar.q2, PolyphonicChar.q3, PolyphonicChar.q4, PolyphonicChar.q5],
            "R" : [PolyphonicChar.r1],
            "S" : [PolyphonicChar.s1, PolyphonicChar.s2, PolyphonicChar.s3, PolyphonicChar.s4],
            "X" : [PolyphonicChar.x1, PolyphonicChar.x2],
            "Y" : [PolyphonicChar.y1, PolyphonicChar.y2, PolyphonicChar.y3, PolyphonicChar.y4],
            "Z" : [PolyphonicChar.z1, PolyphonicChar.z2, PolyphonicChar.z3, PolyphonicChar.z4, PolyphonicChar.z5]
        ]
        nameSectionTitles = (names.allKeys as! [String]).sorted() as NSArray
    }

    @IBAction func masterSwitchDidTap(_ sender: UISwitch) {
        for polyphonic in PolyphonicChar.all {
            UserDefaults.standard.set(sender.isOn, forKey: polyphonic.key)
            setMasterLabelText(sender.isOn)
            UserDefaults.standard.set(sender.isOn, forKey: kEnableAllPolyphonicChars)
            // Just for UI, did not store values.
            executeAfterDelay(0.2, closure: { [weak self] in
                guard let self = self else { return }
                for cell in self.tableView.visibleCells {
                    if let cell = cell as? PolyphonicTableViewCell { cell.polyphonicSwitch.isOn = sender.isOn }
                }
            })
        }
    }

    private func setMasterLabelText(_ on: Bool) {
        masterLabel?.text = on ? NSLocalizedString("Enable All", comment: "") : NSLocalizedString("Disable All", comment: "")
    }
}

// MARK: - Table View Data Source
extension PolyphonicViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return nameSectionTitles.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionTitle = nameSectionTitles.object(at: section)
        let sectionNames = names.object(forKey: sectionTitle) as AnyObject?
        return sectionNames?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nameSectionTitles.object(at: section) as? String
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return UILocalizedIndexedCollation.current().sectionIndexTitles
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: PolyphonicTableViewCell.self, for: indexPath)
        let sectionTitle = nameSectionTitles.object(at: indexPath.section)
        let sectionNames = names.object(forKey: sectionTitle) as? NSArray
        if let name = sectionNames?.object(at: indexPath.row) as? Polyphonic {
            cell.nameLabel?.text = name.character
            cell.polyphonicLabel?.text = "『 \(name.pinyin) 』"
            cell.polyphonicSwitch?.isOn = name.on
            cell.polyphonicKey = name.key
        }
        return cell
    }
}

// MARK: - Table View Delegate
extension PolyphonicViewController {
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        super.tableView(tableView, willDisplayHeaderView: view, forSection: section)
        (view as! UITableViewHeaderFooterView).contentView.backgroundColor = GLOBAL_LIGHT_GRAY_COLOR
        headerViewContainer.frame.size = headerViewContainer.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
}

// MARK: - Rotation
extension PolyphonicViewController {
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        guard UIDevice.current.isPad else { return }
        dismiss(animated: true, completion: {
            kShouldRepresentPolyphonicVC = true
        })
    }
}

