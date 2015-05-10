#!/usr/bin/env cato 1.2

/*
	A script for syncing data between Sphere.IO and Contentful.
 */

import AFNetworking
import Alamofire
import AppKit
import Chores
import ContentfulDeliveryAPI
import ContentfulManagementAPI
import ISO8601DateFormatter
import Result
import SphereIO // Note: has to be added manually as a development Pod

NSApplicationLoad()

let contentfulToken = NSProcessInfo.processInfo().environment["CONTENTFUL_MANAGEMENT_API_ACCESS_TOKEN"] as! String
let contentfulClient = CMAClient(accessToken: contentfulToken)

let clientId = (>["pod", "keys", "get", "SphereIOClientId"]).stderr
let clientSecret = (>["pod", "keys", "get", "SphereIOClientSecret"]).stderr

let project = "ecomhack-demo-67"
let sphereClient = SphereIOClient(clientId: clientId, clientSecret: clientSecret, project: project)

extension String {
    var floatValue: Float {
        return (self as NSString).floatValue
    }
}

func createEntry(space: CMASpace, type: CMAContentType, product: Product) {
    let fields: [NSObject : AnyObject] = [
        "nJpobh9I3Yle0lnN": [ "en-US": product.identifier ],
        "name": [ "en-US": product.name ],
        "productDescription": [ "en-US": product.productDescription ],
        "price": [ "en-US": (product.price["amount"]!).floatValue ],
    ]

    space.createEntryOfContentType(type, withFields: fields, success: { (_, entry) in
        println(entry)
    }) { (_, error) in println(error) }
}

func handleSpace(space: CMASpace, products: [Product]) {
    space.fetchContentTypeWithIdentifier("F94etMpd2SsI2eSq4QsiG", success: { (_, type) in
        println(type)

        for (index, product) in enumerate(products) {
            createEntry(space, type, product)
        }
    }) { (_, error) in println(error) }
}

sphereClient.fetchProductData() { (result) in
	if let value = result.value, results = value["results"] as? [[String:AnyObject]] {
		let products = results.map { (res) in Product(res) }

        contentfulClient.fetchSpaceWithIdentifier("jx9s8zvjjls9", success: { (_, space) in
            handleSpace(space, products)
        }) { (_, error) in println(error) }
	} else {
		fatalError("Failed to retrieve products from Sphere.IO")
	}
}

NSApp.run()
