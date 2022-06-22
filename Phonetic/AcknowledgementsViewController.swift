//
//  AcknowledgementsViewController.swift
//  Phonetic
//
//  Created by Augus on 5/15/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

// REFERENCE: https://github.com/lexrus/VPNOn/blob/master/VPNOn/Acknowledgements.swift

import SafariServices
import UIKit

final class AcknowledgementsViewController: UITableViewController, SFSafariViewControllerDelegate {
    @IBOutlet private var swiftIconButton: UIButton! {
        didSet {
            swiftIconButton.addTarget(self, action: #selector(checkSwiftOrg), for: .touchUpInside)
        }
    }

    private var acknowledgements: [NSDictionary] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: .close, style: .done, target: self, action: .dismissAnimated)
        tableView.estimatedRowHeight = 240
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorColor = .phoneticLightGray
        tableView.backgroundColor = UIColor.phoneticLightGray.darker(0.3)
        guard let plistURL = Bundle.main.url(forResource: "Acknowledgements", withExtension: "plist") else {
            assert(true, "Failed to load Acknowledgements.plist")
            return
        }
        guard let array = NSArray(contentsOf: plistURL) as? [NSDictionary] else { return }
        acknowledgements = array
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return acknowledgements.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: AcknowledgementCell.self, for: indexPath)
        let acknowledgement = acknowledgements[indexPath.row]
        cell.titleLabel.text = acknowledgement.object(forKey: "title") as? String
        cell.licenseLabel.text = acknowledgement.object(forKey: "license") as? String
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let url = acknowledgements[indexPath.row].object(forKey: "link") as? String else { return }
        check(url)
    }

    private func check(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = self
        present(safariVC, animated: true, completion: nil)
    }

    @objc private func checkSwiftOrg() {
        check("https://swift.org")
    }
}
