//
//  Product.swift
//  WatchButton
//
//  Created by Boris Bügling on 09/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Foundation

// Little bit evil model object, because it tends to fatalError() :-)
public struct Product: Printable {
    private let LANG = "de"
    let data: [String:AnyObject]

    public init(_ data: [String:AnyObject]) {
        self.data = data
    }

    public var description: String {
        if let amount = price["amount"], currency = price["currency"] {
            return "\(name) \(amount) \(currency)"
        }

        fatalError("Product has no price.")
    }

    public var productDescription: String { return translatedAttribute("description") }
    public var name: String { return translatedAttribute("name") }

    public var identifier: String {
        if let id = data["id"] as? String {
            return id
        }

        fatalError("Product has no identifier.")
    }

    public var imageUrl: String {
         if let images = variant["images"] as? [[String:AnyObject]], image = images.first, url = image["url"] as? String {
            return url
        }

        fatalError("Product has no image URL.")
    }

    public var price: [String:String] {
        if let prices = variant["prices"] as? [[String:AnyObject]], price = prices.first, value = price["value"] as? [String:AnyObject], amount = value["centAmount"] as? Int, currency = value["currencyCode"] as? String {
            return [ "amount": String(format:"%.2f", Float(amount) / 100.0), "currency": currency ]
        }

        fatalError("Product has no price.")
    }

    private var variant: [String:AnyObject] {
        if let variant = data["masterVariant"] as? [String:AnyObject] {
            return variant
        }

        fatalError("Product has no master variant.")
    }

    private func translatedAttribute(name: String) -> String {
        if let translated = data[name] as? [String:AnyObject], value = translated[LANG] as? String {
            return value
        }

        fatalError("Product has no \(name).")
    }
}
