//
//  PaymentAlert.swift
//  WatchButton
//
//  Created by Boris Bügling on 09/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Foundation
import WatchKit

class PaymentAlert: WKInterfaceController {
    @IBOutlet weak var infoLabel: WKInterfaceLabel!

    override func awakeWithContext(context: AnyObject?) {
        if let paid = context as? Bool {
            if paid {
                infoLabel.setText("Ordered successfully! 💸")
                return
            }
        }

        infoLabel.setText("Order failed... 😭")
    }
}
