//
//  PolyphonicViewController.swift
//  Phonetic
//
//  Created by Augus on 2/23/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


class PolyphonicViewController: BaseTableViewController {
    
    private let kEnableAllPolyphonicChars = "kEnableAllPolyphonicCharacters"
    
    private var names: NSDictionary!
    private var nameSectionTitles: NSArray!
    private var nameIndexTitles: [String]!
    
    @IBOutlet weak var masterSwitch: UISwitch! {
        didSet {
            setMasterLabelText(masterSwitch.isOn)
        }
    }
    
    @IBOutlet weak var masterLabel: UILabel!
    @IBOutlet weak var headerViewContainer: UIView!
    @IBOutlet weak var masterSwitchTrailingConstraint: NSLayoutConstraint!

    override func loadView() {
        super.loadView()
        _title = NSLocalizedString("Polyphonic Characters", comment: "SettingsNavigationController title - Polyphonic Chararcters")
        tableView.sectionIndexBackgroundColor = UIColor.clear
        tableView.sectionIndexColor = UIColor.white
        
        masterSwitch.onTintColor = GLOBAL_CUSTOM_COLOR
        masterSwitch.shouldSwitch(kEnableAllPolyphonicChars, defaultBool: true)
        
        UIDevice.isPad ? masterSwitchTrailingConstraint.constant = 42 : ()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        names = [
            "B" : [PolyphonicChar.b1, PolyphonicChar.b2, PolyphonicChar.b3],
            "C" : [PolyphonicChar.c1, PolyphonicChar.c2, PolyphonicChar.c3],
            "D" : [PolyphonicChar.d1],
            "G" : [PolyphonicChar.g1, PolyphonicChar.g2],
            "H" : [PolyphonicChar.h1],
            "J" : [PolyphonicChar.j1],
            "K" : [PolyphonicChar.k1],
            "M" : [PolyphonicChar.m1, PolyphonicChar.m2],
            "O" : [PolyphonicChar.o1],
            "P" : [PolyphonicChar.p1, PolyphonicChar.p2],
            "Q" : [PolyphonicChar.q1, PolyphonicChar.q2, PolyphonicChar.q3],
            "R" : [PolyphonicChar.r1],
            "S" : [PolyphonicChar.s1, PolyphonicChar.s2, PolyphonicChar.s3],
            "X" : [PolyphonicChar.x1],
            "Y" : [PolyphonicChar.y1, PolyphonicChar.y2, PolyphonicChar.y3, PolyphonicChar.y4],
            "Z" : [PolyphonicChar.z1, PolyphonicChar.z2, PolyphonicChar.z3, PolyphonicChar.z4, PolyphonicChar.z5]
        ]

        nameSectionTitles = (names.allKeys as! [String]).sorted()
        nameIndexTitles   = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func masterSwitchDidTap(_ sender: UISwitch) {
        
        for polyphonic in PolyphonicChar.all {
            UserDefaults.standard.set(sender.isOn, forKey: polyphonic.key)
            
            if UserDefaults.standard.synchronize() {
                
                setMasterLabelText(sender.isOn)
                
                UserDefaults.standard.set(sender.isOn, forKey: kEnableAllPolyphonicChars)
                UserDefaults.standard.synchronize()
                
                // Just for UI, did not store values.
                executeAfterDelay(0.2, closure: {
                    for cell in self.tableView.visibleCells {
                        if let cell = cell as? PolyphonicTableViewCell {
                            cell.polyphonicSwitch.isOn = sender.isOn
                        }
                    }
                })
                
            } else {
                // Store values failed, set switch status backwards.
                masterSwitch.setOn(sender.isOn, animated: true)
            }
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
        let sectionNames = names.object(forKey: sectionTitle)
        return sectionNames?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nameSectionTitles.object(at: section) as? String
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: String(PolyphonicTableViewCell.self), for: indexPath) as? PolyphonicTableViewCell {
            let sectionTitle = nameSectionTitles.object(at: indexPath.section)
            let sectionNames = names.object(forKey: sectionTitle)
            if let name = sectionNames?.object(at: indexPath.row) as? Polyphonic {
                cell.nameLabel?.text = name.character
                cell.polyphonicLabel?.text = "『 \(name.pinyin) 』"
                cell.polyphonicSwitch?.isOn = name.on
                cell.polyphonicKey = name.key
            }
            
            return cell
        }
        return UITableViewCell()
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return nameIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return nameSectionTitles.index(of: title)
    }
    
}

// MARK: - Table View Delegate
extension PolyphonicViewController {
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        super.tableView(tableView, willDisplayHeaderView: view, forSection: section)
        
        (view as! UITableViewHeaderFooterView).contentView.backgroundColor = kNavigationBarBackgroundColor
        
        headerViewContainer.frame.size = headerViewContainer.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
    }
    
}


// MARK: - Rotation
extension PolyphonicViewController {
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if UIDevice.isPad {
            dismissViewController(completion: {
                kShouldRepresentPolyphonicVC = true
            })
        }
    }

}
