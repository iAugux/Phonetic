// Created by Augus on 6/17/21
// Copyright © 2021 Augus <iAugux@gmail.com>

import Foundation

private class Inner {}

enum APP {
    static var version: String? {
        return Bundle(for: Inner.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    static var build: String? {
        return Bundle(for: Inner.self).object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
    }

    static func reviewURL(with id: String) -> URL {
        return URL(string: appStorePath(with: id) + "?action=write-review")!
    }

    private static func appStorePath(with id: String) -> String {
        return "https://itunes.apple.com/app/id\(id)"
    }
}
