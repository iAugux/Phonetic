//
//  Utils.swift
//
//  Created by Augus on 11/10/15.
//  Copyright © 2015 iAugus. All rights reserved.
//

import Foundation


public typealias Closure = () -> ()


class Utils {
    
    class var documentPath: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    }
    
    class func documentPathWithFile(_ name: String) -> String {
        return (documentPath as NSString).appendingPathComponent(name)
    }
    
    class func appGroupDocumentPath(_ appGroupId: String) -> String? {
        let url = FileManager.default.containerURLForSecurityApplicationGroupIdentifier(appGroupId)
        let path = url?.absoluteString?.replacingOccurrences(of: "file:", with: "", options: .literal, range: nil)
        return path
    }
    
}

var GlobalMainQueue: DispatchQueue {
    return DispatchQueue.main
}

var GlobalUserInteractiveQueue: DispatchQueue {
    return DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes(rawValue: UInt64(DispatchQueueAttributes.qosUserInteractive.rawValue)))
}

var GlobalUserInitiatedQueue: DispatchQueue {
    return DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes(rawValue: UInt64(DispatchQueueAttributes.qosUserInitiated.rawValue)))
}

var GlobalUtilityQueue: DispatchQueue {
    return DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes(rawValue: UInt64(DispatchQueueAttributes.qosUtility.rawValue)))
}

var GlobalBackgroundQueue: DispatchQueue {
    return DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes(rawValue: UInt64(DispatchQueueAttributes.qosBackground.rawValue)))
}

// MARK: - Delay

func executeAfterDelay(_ seconds: Double, closure: (() -> Void)) {
    DispatchQueue.main.after(when: .now() + seconds) {
        closure()
    }
}
