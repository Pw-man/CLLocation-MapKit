//
//  Extensions.swift
//  CLLocation&MapKit
//
//  Created by Роман on 26.04.2022.
//

import UIKit

extension UIViewController {
    func presentSimpleAlertController(title: String, message: String, actionMessage: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: actionMessage, style: .default)
        alertController.addAction(action)
        self.present(alertController, animated: true)
    }
}
