// Created by Augus on 2/3/16
// Copyright © 2016 Augus <iAugux@gmail.com>

import UIKit

#if DEBUG
@MainActor
final class AlertController: NSObject {
    private static let ok = String(localized: "OK")

    class func alert(_ title: String = "", message: String = "", actionTitle: String = ok, completionHandler: Closure? = nil) {
        let okAction = UIAlertAction(title: actionTitle, style: .default) { _ in
            if let completion = completionHandler {
                completion()
            }
        }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(okAction)
        UIApplication.shared.topMostViewController?.present(alertController, animated: true, completion: nil)
    }

    class func multiAlertsWithOptions(_ multiItemsOfInfo: [String], completionHandler: Closure?) {
        alertWithOptions(multiItemsOfInfo, completionHandler: completionHandler)
    }

    private class func alertWithOptions(_ multiItemsOfInfo: [String], completionHandler: Closure?) {
        Task { @MainActor in
            var tempInfoArray = multiItemsOfInfo
            let cancelAction = UIAlertAction(title: String(localized: "Cancel"), style: .cancel, handler: { _ in
                tempInfoArray.removeAll()
            })
            let okAction = UIAlertAction(title: String(localized: "OK"), style: .default, handler: { _ in
                tempInfoArray.removeFirst()
                if tempInfoArray.isEmpty {
                    completionHandler?()
                }
                self.alertWithOptions(tempInfoArray, completionHandler: {
                    completionHandler?()
                })
            })
            guard !tempInfoArray.isEmpty else { return }
            let alertController = UIAlertController(title: nil, message: tempInfoArray.first, preferredStyle: .alert)
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            UIApplication.shared.topMostViewController?.present(alertController, animated: true, completion: nil)
        }
    }
}
#endif

extension UIAlertController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = .systemBlue
    }
}
