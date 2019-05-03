//
//  AlertController.swift
//  Phonetic
//
//  Created by Augus on 2/3/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

final class AlertController: NSObject {
    private static let ok = NSLocalizedString("OK", comment: "")

    class func alert(_ title: String = "", message: String = "", actionTitle: String = ok, completionHandler: Closure?) {
        AlertController.alert(title, message: message, actionTitle: actionTitle, addCancelAction: false, completionHandler: completionHandler, canceledHandler: nil)
    }

    class func alertWithCancelAction(_ title: String = "", message: String = "", actionTitle: String = ok, completionHandler: Closure?, canceledHandler: Closure?) {
        AlertController.alert(title, message: message, actionTitle: actionTitle, addCancelAction: true, completionHandler: completionHandler, canceledHandler: canceledHandler)
    }

    class func multiAlertsWithOptions(_ multiItemsOfInfo: [String], completionHandler: Closure?) {
        alertWithOptions(multiItemsOfInfo, completionHandler: completionHandler)
    }

    private class func alert(_ title: String = "", message: String = "", actionTitle: String = ok, addCancelAction: Bool, completionHandler: Closure?, canceledHandler: Closure?) {
        let okAction = UIAlertAction(title: actionTitle, style: .default) { _ in
            if let completion = completionHandler {
                completion()
            }
        }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if addCancelAction {
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
                if let handler = canceledHandler {
                    handler()
                }
            }
            alertController.addAction(cancelAction)
        }
        alertController.addAction(okAction)
        UIApplication.shared.topMostViewController?.present(alertController, animated: true, completion: nil)
    }

    private class func alertWithOptions(_ multiItemsOfInfo: [String], completionHandler: Closure?) {
        DispatchQueue.main.async {
            var tempInfoArray = multiItemsOfInfo
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                tempInfoArray.removeAll()
            })
            let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
                tempInfoArray.removeFirst()
                if tempInfoArray.count == 0 { completionHandler?() }
                self.alertWithOptions(tempInfoArray, completionHandler: {
                    completionHandler?()
                })
            })
            guard tempInfoArray.count > 0 else { return }
            let alertController = UIAlertController(title: nil, message: tempInfoArray.first, preferredStyle: .alert)
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            UIApplication.shared.topMostViewController?.present(alertController, animated: true, completion: nil)
        }
    }
}
