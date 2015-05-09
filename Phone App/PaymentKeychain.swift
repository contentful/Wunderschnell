//
//  PaymentKeychain.swift
//  WatchButton
//
//  Created by Boris Bügling on 09/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import KeychainAccess

let WBKeychainName      = "org.vu0.WatchButton.PayPal"
let WBKeychainService   = "org.vu0.WatchButton"

// FIXME: Hard-coded shipping address due to time constraints :(
func retrieveShippingAddress() -> Address {
    return Address(firstName: "YOLO Bert", lastName: "Thiefenthaler", streetName: "Ritterstr.", streetNumber: "23", postalCode: "10249", city: "Berlin", country: "DE")
}

func retrievePaymentId() -> String {
    let keychain = Keychain(service: WBKeychainService)
    return keychain[WBKeychainName] ?? ""
}

func storePaymentId(paymentId: String) {
    let keychain = Keychain(service: WBKeychainService)
    keychain[WBKeychainName] = paymentId
}
