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
            setMasterLabelText(masterSwitch.on)
        }
    }
    
    @IBOutlet weak var masterLabel: UILabel!
    @IBOutlet weak var headerViewContainer: UIView!
    
    override func loadView() {
        super.loadView()
        _title = NSLocalizedString("Polyphonic Characters", comment: "SettingsNavigationController title - Polyphonic Chararcters")
        tableView.sectionIndexBackgroundColor = UIColor.clearColor()
        tableView.sectionIndexColor = UIColor.whiteColor()
        
        masterSwitch.onTintColor = GLOBAL_CUSTOM_COLOR
        masterSwitch.shouldSwitch(kEnableAllPolyphonicChars, defaultBool: true)
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

        nameSectionTitles = (names.allKeys as! [String]).sort()
        nameIndexTitles   = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func masterSwitchDidTap(sender: UISwitch) {
        
        for polyphonic in PolyphonicChar.all {
            NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey: polyphonic.key)
            
            if NSUserDefaults.standardUserDefaults().synchronize() {
                
                setMasterLabelText(sender.on)
                
                NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey: kEnableAllPolyphonicChars)
                NSUserDefaults.standardUserDefaults().synchronize()
                
                // Just for UI, did not store values.
                executeAfterDelay(0.2, completion: {
                    for cell in self.tableView.visibleCells {
                        if let cell = cell as? PolyphonicTableViewCell {
                            cell.polyphonicSwitch.on = sender.on
                        }
                    }
                })
                
            } else {
                // Store values failed, set switch status backwards.
                masterSwitch.setOn(sender.on, animated: true)
            }
        }
        
    }
    
    private func setMasterLabelText(on: Bool) {
        masterLabel?.text = on ? NSLocalizedString("Enable All", comment: "") : NSLocalizedString("Disable All", comment: "")
    }
    
}

// MARK: - Table View Data Source
extension PolyphonicViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return nameSectionTitles.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionTitle = nameSectionTitles.objectAtIndex(section)
        let sectionNames = names.objectForKey(sectionTitle)
        return sectionNames?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nameSectionTitles.objectAtIndex(section) as? String
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier(String(PolyphonicTableViewCell), forIndexPath: indexPath) as? PolyphonicTableViewCell {
            let sectionTitle = nameSectionTitles.objectAtIndex(indexPath.section)
            let sectionNames = names.objectForKey(sectionTitle)
            if let name = sectionNames?.objectAtIndex(indexPath.row) as? Polyphonic {
                cell.nameLabel?.text = name.character
                cell.polyphonicLabel?.text = "『 \(name.pinyin) 』"
                cell.polyphonicSwitch?.on = name.on
                cell.polyphonicKey = name.key
            }
            
            return cell
        }
        return UITableViewCell()
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return nameIndexTitles
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return nameSectionTitles.indexOfObject(title)
    }
    
}

// MARK: - Table View Delegate
extension PolyphonicViewController {
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        super.tableView(tableView, willDisplayHeaderView: view, forSection: section)
        
        (view as! UITableViewHeaderFooterView).contentView.backgroundColor = kNavigationBarBackgroundColor
        
        headerViewContainer.frame.size = headerViewContainer.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
    }
    
}


// MARK: - Rotation
extension PolyphonicViewController {
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        if UIDevice.isPad {
            dismissViewController(completion: {
                kShouldRepresentPolyphonicVC = true
            })
        }
    }

}