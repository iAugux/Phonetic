//
//  DEBUGLog.swift
//
//  Created by Augus on 2/21/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation

#if DEBUG
    
    func DEBUGLog(message: String, filename: NSString = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        NSLog("[\(filename.lastPathComponent):\(line)] \(function) - \(message)")
    }
    
    func DEBUGLog(message: AnyObject, filename: NSString = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        NSLog("[\(filename.lastPathComponent):\(line)] \(function) - \(message)")
    }
    
#else
    
    func DEBUGLog(message: String, filename: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
    }
    
    func DEBUGLog(message: AnyObject, filename: NSString = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
    }
    
#endif