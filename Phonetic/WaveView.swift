//
//  WaveView.swift
//  Phonetic
//
//  Created by Augus on 1/29/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

class WaveView: UIWebView {

    override func awakeFromNib() {
        super.awakeFromNib()

        let html = NSBundle.mainBundle().pathForResource("index", ofType: "html")
        do {
            let contents = try String(contentsOfFile: html!, encoding: NSUTF8StringEncoding)
            let url = NSURL(fileURLWithPath: html!)
            loadHTMLString(contents, baseURL: url)
        } catch {

            DEBUGLog("\(error)")
        }
    }

}
