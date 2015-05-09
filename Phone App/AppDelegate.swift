//
//  AppDelegate.swift
//  WatchButton
//
//  Created by Boris Bügling on 09/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Keys
import UIKit

// Change the used sphere.io project here
let SphereIOProject = "ecomhack-demo-67"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var client: PayPalClient?
    let keys = WatchButtonKeys()
    var selectedProduct: [String:AnyObject]?
    var sphereClient: SphereIOClient!
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        PayPalMobile.initializeWithClientIdsForEnvironments([ PayPalEnvironmentSandbox: WatchButtonKeys().payPalSandboxClientId()])

        sphereClient = SphereIOClient(clientId: keys.sphereIOClientId(), clientSecret: keys.sphereIOClientSecret(), project: SphereIOProject)
        return true
    }

    func application(application: UIApplication, handleWatchKitExtensionRequest userInfo: [NSObject : AnyObject]?, reply: (([NSObject : AnyObject]!) -> Void)!) {
        if let reply = reply, userInfo = userInfo, command = userInfo[CommandIdentifier] as? String {
            switch(Command(rawValue: command)!) {
            case .GetProduct:
                fetchSelectedProduct() {
                    if let product = self.selectedProduct {
                        reply([Reply.Product.rawValue: product])
                    }
                    return
                }
                break
            case .MakeOrder:
                sphereClient.quickOrder(product: self.selectedProduct!, to: retrieveShippingAddress()) { (result) in
                    if let order = result.value {
                        if let client = self.client {
                            let pp = Product(data: self.selectedProduct!)
                            let amount = pp.price["amount"]!
                            let currency = pp.price["currency"]!

                            client.pay(retrievePaymentId(), currency, amount) { (paid) in
                                reply([Reply.Paid.rawValue: paid])

                                self.sphereClient.setPaymentState(paid ? .Paid : .Failed, forOrder: order) { (result) in
                                    println("Payment state result: \(result)")
                                }
                            }
                        } else {
                            fatalError("Could not process payment request from watch")
                        }
                    }
                }
                break
            }
        } else {
            fatalError("Invalid WatchKit extension request :(")
        }

        // Keep the phone app running a bit for demonstration purposes
        UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler() {}
    }

    // MARK: - Helpers

    func fetchSelectedProduct(completion: () -> ()) {
        if selectedProduct != nil {
            completion()
            return
        }

        sphereClient.fetchProductData() { (result) in
            if let value = result.value, results = value["results"] as? [[String:AnyObject]], product = results.first {
                self.selectedProduct = product
                completion()
            } else {
                fatalError("Failed to retrieve products from Sphere.IO")
            }
        }
    }
}
