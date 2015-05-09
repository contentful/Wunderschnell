//
//  AppDelegate.swift
//  WatchButton
//
//  Created by Boris Bügling on 09/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let myAddress = Address(firstName: "YOLO Bert", lastName: "Thiefenthaler", streetName: "Ritterstr.", streetNumber: "23", postalCode: "10249", city: "Berlin", country: "DE")

        let client = SphereIOClient(clientId: "krcX5hT2bH6Z-zIN-DArpWko", clientSecret: "qa3deqJ-PV6p9pN_UgLxLnZ4JjTx3Q3o", project: "ecomhack-demo-67")

        client.fetchProductData() { (result) in
            if let value = result.value, results = value["results"] as? [[String:AnyObject]], product = results.first {
                //println(product)

                client.createCart("EUR") { (result) in
                    if let cart = result.value {
                        client.addProduct(product, quantity: 1, toCart: cart) { (result) in
                            if let cart = result.value {
                                client.addShippingAddress(myAddress, toCart: cart) { (result) in
                                    if let cart = result.value {
                                        client.createOrder(forCart: cart) { (result) in
                                            if let order = result.value {
                                                client.setPaymentState(.Paid, forOrder: order) { (result) in
                                                    println(result)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
