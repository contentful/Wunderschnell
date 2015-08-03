//
//  PaymentKeychain.swift
//  WatchButton
//
//  Created by Boris Bügling on 09/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Cube
import KeychainAccess

let WBKeychainId            = "org.vu0.WatchButton.PayPal.PaymentId"
let WBKeychainRefreshToken  = "org.vu0.WatchButton.PayPal.RefreshToken"
let WBKeychainService       = "org.vu0.WatchButton"

func retrieveShippingAddress() -> Address {
    return AddressFormViewController.DefaultAddress
}

func retrieveRefreshToken() -> String {
    let keychain = Keychain(service: WBKeychainService)
    return keychain[WBKeychainRefreshToken] ?? ""
}

func retrievePaymentId() -> String {
    let keychain = Keychain(service: WBKeychainService)
    return keychain[WBKeychainId] ?? ""
}

func storeRefreshToken(refreshToken: String) {
    let keychain = Keychain(service: WBKeychainService)
    keychain[WBKeychainRefreshToken] = refreshToken
}

func storePaymentId(paymentId: String) {
    let keychain = Keychain(service: WBKeychainService)
    keychain[WBKeychainId] = paymentId
}
