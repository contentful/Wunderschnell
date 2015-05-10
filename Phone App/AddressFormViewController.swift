//
//  AddressFormViewController.swift
//  WatchButton
//
//  Created by Boris Bügling on 10/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Form
import UIKit

class AddressFormViewController: FORMViewController {
    static let DefaultAddress = Address(firstName: "YOLO Bert", lastName: "Thiefenthaler", streetName: "Ritterstr.", streetNumber: "23", postalCode: "10249", city: "Berlin", country: "DE")

    required init(coder aDecoder: NSCoder) {
        fatalError("Not supported.")
    }

    private static func group(fields: [[String:AnyObject]]) -> [String:AnyObject] {
        return [ "id": "group-id", "title": "Address", "sections": [ [ "id":  "section-0", "fields": fields ] ] ]
    }

    private static func addressJSON() -> [[String:AnyObject]] {
        let keys = [String](DefaultAddress.toDictionary().keys).sorted { $0 < $1 }
        let fields: [[String:AnyObject]] = keys.map { (key) in
            return [ "id": key, "title": key, "type": "text" ]
        }

        return [ group(fields) ]
    }

    override class func initialize() {
        FORMDefaultStyle.applyStyle()
    }

    init() {
        super.init(JSON: self.dynamicType.addressJSON(), andInitialValues: self.dynamicType.DefaultAddress.toDictionary(), disabled: false)
    }
}
