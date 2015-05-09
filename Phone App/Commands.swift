//
//  Commands.swift
//  WatchButton
//
//  Created by Boris Bügling on 09/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Foundation

public let CommandIdentifier = "org.vu0.command"

public enum Command : String {
    case GetProduct = "GetProducts"
    case MakeOrder = "MakeOrder"
}

public enum Reply : String {
    case Paid = "Paid"
    case Product = "Product"
}
