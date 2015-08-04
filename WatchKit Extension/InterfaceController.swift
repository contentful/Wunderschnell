//
//  InterfaceController.swift
//  WatchButton WatchKit Extension
//
//  Created by Boris Bügling on 09/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Cube
import Foundation
import MMWormhole
import WatchConnectivity
import WatchKit

class InterfaceController: WKInterfaceController {
    let wormhole = MMWormhole(applicationGroupIdentifier: AppGroupIdentifier, optionalDirectory: DirectoryIdentifier)

    @IBOutlet weak var productImage: WKInterfaceImage!
    @IBOutlet weak var productPrice: WKInterfaceLabel!

    override func willActivate() {
        super.willActivate()

        WCSession.defaultSession().sendMessage([ CommandIdentifier: Command.GetProduct.rawValue ], replyHandler: { (data) in
            let product = Product(data[Reply.Product.rawValue] as! [String:AnyObject])

            if let amount = product.price["amount"], currency = product.price["currency"] {
                self.productPrice.setText("\(amount) \(currency)")
            }

            NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: NSURL(string: product.imageUrl)!)) { (data, _, _) in
                if let data = data {
                    self.productImage.setImage(UIImage(data: data))
                }
            }
        }, errorHandler: nil)
    }

    @IBAction func tapped() {
        wormhole.listenForMessageWithIdentifier(Reply.Paid.rawValue) { (data) in
            if let paid = data as? Bool {
                self.presentControllerWithName("PaymentAlert", context: paid)
            } else {
                self.presentControllerWithName("PaymentAlert", context: false)
            }
        }

        WCSession.defaultSession().sendMessage([ CommandIdentifier: Command.MakeOrder.rawValue ], replyHandler: { (_) in
            // Seems like openParentApplication() has a too short timeout for our orders.
        }, errorHandler: nil)
    }
}
