//
//  AppDelegate.swift
//  WatchButton
//
//  Created by Boris Bügling on 09/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Keys
import MMWormhole
import UIKit

// Change the used sphere.io project here
let SphereIOProject = "ecomhack-demo-67"

private extension Array {
    func randomItem() -> T {
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let beaconController = BeaconController()
    private let keys = WatchButtonKeys()
    private var sphereClient: SphereIOClient!
    private let wormhole = MMWormhole(applicationGroupIdentifier: AppGroupIdentifier, optionalDirectory: DirectoryIdentifier)

    var selectedProduct: [String:AnyObject]?
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        PayPalMobile.initializeWithClientIdsForEnvironments([ PayPalEnvironmentSandbox: WatchButtonKeys().payPalSandboxClientId()])

        sphereClient = SphereIOClient(clientId: keys.sphereIOClientId(), clientSecret: keys.sphereIOClientSecret(), project: SphereIOProject)

        beaconController.beaconCallback = { (beacon, _) in
            self.wormhole.passMessageObject(true, identifier: Reply.BeaconRanged.rawValue)
        }

        beaconController.outOfRangeCallback = {
            self.wormhole.passMessageObject(false, identifier: Reply.BeaconRanged.rawValue)
        }

        beaconController.refresh()
        return true
    }

    func application(application: UIApplication, handleWatchKitExtensionRequest userInfo: [NSObject : AnyObject]?, reply: (([NSObject : AnyObject]!) -> Void)!) {
        if let reply = reply, userInfo = userInfo, command = userInfo[CommandIdentifier] as? String {
            handleCommand(command, reply)
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
            if let value = result.value, results = value["results"] as? [[String:AnyObject]] {
                self.selectedProduct = results.randomItem()
                completion()
            } else {
                fatalError("Failed to retrieve products from Sphere.IO")
            }
        }
    }

    private func handleCommand(command: String, _ reply: (([NSObject : AnyObject]!) -> Void)) {
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
            fetchSelectedProduct() {
                self.sphereClient.quickOrder(product: self.selectedProduct!, to:retrieveShippingAddress()) { (result) in
                    if let order = result.value {
                        let pp = Product(self.selectedProduct!)
                        let amount = pp.price["amount"]!
                        let currency = pp.price["currency"]!

                        let client = PayPalClient(clientId: self.keys.payPalSandboxClientId(), clientSecret: self.keys.payPalSandboxClientSecret(), code: retrieveRefreshToken())

                        client.pay(retrievePaymentId(), currency, amount) { (paid) in
                            reply([Reply.Paid.rawValue: paid])

                            self.wormhole.passMessageObject(paid, identifier: Reply.Paid.rawValue)
                            self.sphereClient.setPaymentState(paid ? .Paid : .Failed, forOrder: order) { (result) in
                                println("Payment state result: \(result)")
                            }
                        }
                    }
                }
            }
            break
        default:
            break
        }
    }
}
