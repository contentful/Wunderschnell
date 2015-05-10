//
//  InterfaceController.swift
//  WatchButton WatchKit Extension
//
//  Created by Boris Bügling on 09/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Foundation
import MMWormhole
import WatchKit

class InterfaceController: WKInterfaceController {
    let wormhole = MMWormhole(applicationGroupIdentifier: AppGroupIdentifier, optionalDirectory: DirectoryIdentifier)

    @IBOutlet weak var productImage: WKInterfaceImage!
    @IBOutlet weak var productPrice: WKInterfaceLabel!

    override func willActivate() {
        super.willActivate()

        WKInterfaceController.openParentApplication([ CommandIdentifier: Command.GetProduct.rawValue ]) { (data, error) in
            if let data = data, productData = data[Reply.Product.rawValue] as? [String:AnyObject] {
                let product = Product(data: productData)

                if let amount = product.price["amount"], currency = product.price["currency"] {
                    self.productPrice.setText("\(amount) \(currency)")
                }

                NSURLConnection.sendAsynchronousRequest(NSURLRequest(URL: NSURL(string: product.imageUrl)!), queue: NSOperationQueue.mainQueue()) { (_, data, _) in
                    if let data = data {
                        self.productImage.setImage(UIImage(data: data))
                    }
                }
            }
        }
    }

    @IBAction func tapped() {
        wormhole.listenForMessageWithIdentifier(Reply.Paid.rawValue) { (data) in
            if let paid = data as? Bool {
                self.presentControllerWithName("PaymentAlert", context: paid)
            } else {
                self.presentControllerWithName("PaymentAlert", context: false)
            }
        }

        WKInterfaceController.openParentApplication([ CommandIdentifier: Command.MakeOrder.rawValue ]) { (_, _) in
            // Seems like openParentApplication() has a too short timeout for our orders.
        }
    }
}
