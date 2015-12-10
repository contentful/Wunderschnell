//
//  AppDelegate.swift
//  WatchButton
//
//  Created by Boris Bügling on 09/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Cube
import Keys
import MMWormhole
import WatchConnectivity
import UIKit

// Change the used sphere.io project here
let SphereIOProject = "ecomhack-demo-67"

private extension Array {
    func randomItem() -> Element {
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {
    private let beaconController = BeaconController()
    private let keys = WatchbuttonKeys()
    private var sphereClient: SphereIOClient!
    private let wormhole = MMWormhole(applicationGroupIdentifier: AppGroupIdentifier, optionalDirectory: DirectoryIdentifier)

    var selectedProduct: [String:AnyObject]?
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        WCSession.defaultSession().delegate = self
        WCSession.defaultSession().activateSession()

        // TODO: WCSession.defaultSession().reachable

        PayPalMobile.initializeWithClientIdsForEnvironments([ PayPalEnvironmentSandbox: WatchbuttonKeys().payPalSandboxClientId()])

        beaconController.beaconCallback = { (beacon, _) in
            self.wormhole.passMessageObject(true, identifier: Reply.BeaconRanged.rawValue)
        }

        beaconController.outOfRangeCallback = {
            self.wormhole.passMessageObject(false, identifier: Reply.BeaconRanged.rawValue)
        }

        beaconController.refresh()
        return true
    }

    func initializeSphereClient() {
        if sphereClient == nil {
            sphereClient = SphereIOClient(clientId: keys.sphereIOClientId(), clientSecret: keys.sphereIOClientSecret(), project: SphereIOProject)
        }
    }

    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        if let command = message[CommandIdentifier] as? String {
            handleCommand(command, replyHandler)
        } else {
            fatalError("Invalid WatchKit extension request :(")
        }

        // Keep the phone app running a bit for demonstration purposes
        UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler() {}
    }

    // MARK: - Helpers

    func fetchSelectedProduct(completion: () -> ()) {
        initializeSphereClient()

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

    private func handleCommand(command: String, _ reply: (([String : AnyObject]) -> Void)) {
        initializeSphereClient()

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
                                //println("Payment state result: \(result)")

                                if let order = result.value {
                                    self.sphereClient.setState(.Complete, forOrder: order) { (result) in
                                        print("Ordered successfully.")
                                    }
                                } else {
                                    fatalError("Failed to set order to complete state.")
                                }
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
