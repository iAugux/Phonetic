//
//  CustomTableView.swift
//  Phonetic
//
//  Created by Augus on 5/23/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

final class CustomTableView: UITableView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        endEditing(true)
    }
}
