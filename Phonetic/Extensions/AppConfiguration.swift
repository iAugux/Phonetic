//
//  AppConfiguration.swift
//
//  Created by Augus on 2/9/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation



// REFERENCE: http://stackoverflow.com/a/33830605/4656574

enum AppConfiguration {
    case debug
    case testFlight
    case appStore
}

struct Config {
    // This is private because the use of 'appConfiguration' is preferred.
    fileprivate static let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    
    // This can be used to add debug statements.
    static var isDebug: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
    
    static var appConfiguration: AppConfiguration {
        if isDebug {
            return .debug
        } else if isTestFlight {
            return .testFlight
        } else {
            return .appStore
        }
    }
}
