//
//  Commands.swift
//  WatchButton
//
//  Created by Boris Bügling on 09/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Foundation

public let AppGroupIdentifier = "group.vu0.org.WatchButton"
public let CommandIdentifier = "org.vu0.command"
public let DirectoryIdentifier = "WatchButton"

public enum Command : String {
    case GetProduct = "GetProducts"
    case MakeOrder = "MakeOrder"
}

public enum Reply : String {
    case Paid = "Paid"
    case Product = "Product"
}
