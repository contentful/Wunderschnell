//
//  InterfaceController.swift
//  WatchButton WatchKit Extension
//
//  Created by Boris Bügling on 09/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Foundation
import WatchKit

class InterfaceController: WKInterfaceController {
    @IBOutlet weak var productImage: WKInterfaceImage!
    @IBOutlet weak var productPrice: WKInterfaceLabel!

    override func willActivate() {
        super.willActivate()

        WKInterfaceController.openParentApplication([ CommandIdentifier: Command.GetProduct.rawValue ]) { (data, error) in
            if let data = data, productData = data[Reply.Product.rawValue] as? [String:AnyObject] {
                let product = Product(data: productData)

                if let amount = product.price["amount"], currency = product.price["currency"] {
                    let actualAmount = Float(amount.toInt()!) / 100.0
                    self.productPrice.setText("\(actualAmount) \(currency)")
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
        WKInterfaceController.openParentApplication([ CommandIdentifier: Command.MakeOrder.rawValue ]) { (data, error) in
            if let data = data, paid = data[Reply.Paid.rawValue] as? Bool {
                self.presentControllerWithName("PaymentAlert", context: paid)
            } else {
                self.presentControllerWithName("PaymentAlert", context: false)
            }
        }
    }
}
