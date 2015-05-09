//
//  SphereIOClient.swift
//  WatchButton
//
//  Created by Boris Bügling on 09/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Alamofire
import Foundation
import Result

private extension Int {
    func toNumber() -> NSNumber {
        return NSNumber(int: Int32(self))
    }
}

// Somehow using `NSURLAuthenticationChallenge` didn't work against the Sphere API 😭
private struct AuthRequest: URLRequestConvertible {
    private let clientId: String
    private let clientSecret: String
    private let project: String

    var URLRequest: NSURLRequest {
        if let URL = NSURL(string: "https://auth.sphere.io/oauth/token") {
            let URLRequest = NSMutableURLRequest(URL: URL)
            URLRequest.HTTPMethod = Method.POST.rawValue

            let parameters = [ "grant_type": "client_credentials", "scope": "manage_project:\(project)" ]

            let auth = String(format: "%@:%@", clientId, clientSecret).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
            let header = auth.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
            URLRequest.setValue("Basic \(header)", forHTTPHeaderField: "Authorization")

            let encoding = Alamofire.ParameterEncoding.URL
            return encoding.encode(URLRequest, parameters: parameters).0
        }

        fatalError("Broken Authentication URL...")
    }
}

private typealias OAuthResult = Result<String, NSError>
private typealias OAuthClosure = (result: OAuthResult) -> Void
public typealias SphereResult = Result<[String:AnyObject], NSError>
public typealias SphereClosure = (result: SphereResult) -> Void

public struct Address {
    private let firstName: String
    private let lastName: String
    private let streetName: String
    private let streetNumber: String
    private let postalCode: String
    private let city: String
    private let country: String

    public init(firstName: String, lastName: String, streetName: String, streetNumber: String, postalCode: String, city: String, country: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.streetName = streetName
        self.streetNumber = streetNumber
        self.postalCode = postalCode
        self.city = city
        self.country = country
    }

    func toDictionary() -> [String:String] {
        var dictionary = [String:String]()
        let mirror = reflect(self)

        for index in 0 ..< mirror.count {
            let (childKey, childMirror) = mirror[index]

            if let value = childMirror.value as? String {
                dictionary[childKey] = value
            }
        }

        return dictionary
    }
}

public enum OrderState: String {
    case Open = "Open"
    case Complete = "Complete"
    case Cancelled = "Cancelled"
}

public enum PaymentState: String {
    case BalanceDue = "BalanceDue"
    case Failed = "Failed"
    case Pending = "Pending"
    case CreditOwed = "CreditOwed"
    case Paid = "Paid"
}

public class SphereIOClient {
    private let baseURL = "https://api.sphere.io"
    private let clientId: String
    private let clientSecret: String
    private let project: String
    private var token: String?

    private func getToken(completion: OAuthClosure) {
        Alamofire.request(AuthRequest(clientId: clientId, clientSecret: clientSecret, project: project))
            .responseJSON { (_, _, JSON, error) in
                if let json = JSON as? [String:AnyObject], token = json["access_token"] as? String {
                    completion(result: OAuthResult(value: token))
                    return
                }

                if let error = error {
                    completion(result: OAuthResult(error: error))
                    return
                }

                fatalError("Didn't even get an error...")
        }
    }

    private func performAuthenticatedRequest(completion: SphereClosure, _ endpoint: String, _ method: Alamofire.Method = .GET, _ parameters: [String: AnyObject]? = nil) {
        if !validateToken(performAuthenticatedRequest, completion, endpoint, method, parameters) {
            return
        }

        Alamofire.request(sphereRequest(endpoint, method, parameters)).responseJSON { (_, _, JSON, error) in
            self.sphereCompletion(completion, JSON, error)
        }
    }

    private func sphereCompletion(completion: SphereClosure, _ JSON: AnyObject?, _ error: NSError?) {
        if let json = JSON as? [String:AnyObject] {
            completion(result: SphereResult(value: json))
            return
        }

        if let error = error {
            completion(result: SphereResult(error: error))
            return
        }

        fatalError("Didn't even get an error...")
    }

    private func sphereRequest(endpoint: String, _ method: Alamofire.Method, _ parameters: [String: AnyObject]?) -> URLRequestConvertible {
        assert(token != nil, "")

        if let token = token, URL = NSURL(string: "\(baseURL)/\(endpoint)") {
            let URLRequest = NSMutableURLRequest(URL: URL)
            URLRequest.HTTPMethod = method.rawValue

            URLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let encoding = Alamofire.ParameterEncoding.JSON
            return encoding.encode(URLRequest, parameters: parameters).0
        }

        fatalError("Could not create valid request.")
    }

    private func validateToken(function: (completion: SphereClosure, endpoint: String, method: Alamofire.Method, parameters: [String: AnyObject]?) -> Void, _ completion: SphereClosure, _ endpoint: String, _ method: Alamofire.Method, _ parameters: [String: AnyObject]?) -> Bool {
        if token == nil {
            getToken() { (result) in
                result.analysis(ifSuccess: { (token) in
                    self.token = token
                    function(completion: completion, endpoint: endpoint, method: method, parameters: parameters)
                    }, ifFailure: { (error) in
                        completion(result: SphereResult(error: error))
                })
            }

            return false
        }

        return true
    }

    // MARK: - Action helpers

    private func performAction(action: [String:AnyObject], onCart cart: [String:AnyObject], _ completion: SphereClosure) {
        if let cartId = cart["id"] as? String, cartVersion = cart["version"] as? Int {
            performAuthenticatedRequest(completion, "\(project)/carts/\(cartId)", .POST, ["version": cartVersion.toNumber(), "actions": [action]])
        } else {
            fatalError("Could not perform action on cart.")
        }
    }

    private func performAction(action: [String:AnyObject], onOrder order: [String:AnyObject], _ completion: SphereClosure) {
        if let orderId = order["id"] as? String, orderVersion = order["version"] as? Int {
            performAuthenticatedRequest(completion, "\(project)/orders/\(orderId)", .POST, ["version": orderVersion.toNumber(), "actions": [action]])
        } else {
            fatalError("Could not perform action on order.")
        }
    }

    // MARK: - Public API

    public init(clientId: String, clientSecret: String, project: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.project = project
    }

    public func fetchProductData(completion: SphereClosure) {
        performAuthenticatedRequest(completion, "\(project)/product-projections")
    }

    // MARK: - Public API for Carts

    public func addProduct(product: [String:AnyObject], quantity: Int, toCart cart: [String:AnyObject], _ completion: SphereClosure) {
        if let productId = product["id"] as? String, masterVariant = product["masterVariant"] as? [String:AnyObject], variantId = masterVariant["id"] as? Int {
            performAction(["action": "addLineItem", "productId": productId, "variantId": variantId.toNumber(), "quantity": quantity.toNumber()], onCart: cart, completion)
        } else {
            fatalError("Could not add product to cart")
        }
    }

    public func addShippingAddress(address: Address, toCart cart: [String:AnyObject], _ completion: SphereClosure) {
        performAction(["action": "setShippingAddress", "address": address.toDictionary()], onCart: cart, completion)
    }

    public func createCart(currency: String, _ completion: SphereClosure) {
        performAuthenticatedRequest(completion, "\(project)/carts", .POST, ["currency": currency])
    }

    public func queryCart(cartId: String, _ completion: SphereClosure) {
        performAuthenticatedRequest(completion, "\(project)/carts/\(cartId)")
    }

    public func recalculateCart(forCart cart: [String:AnyObject], _ completion: SphereClosure) {
        performAction(["action": "recalculate"], onCart: cart, completion)
    }

    public func setShippingMethod(forCart cart: [String:AnyObject], _ completion: SphereClosure) {
        performAction(["action": "setShippingMethod"], onCart: cart, completion)
    }

    // MARK - Public API for Orders

    public func createOrder(forCart cart: [String:AnyObject], _ completion: SphereClosure) {
        if let cartId = cart["id"] as? String, cartVersion = cart["version"] as? Int {
            performAuthenticatedRequest(completion, "\(project)/orders", .POST, ["version": cartVersion.toNumber(), "id": cartId, "orderNumber": cartId])
        } else {
            fatalError("Could not create order for cart")
        }
    }

    public func queryOrder(orderId: String, _ completion: SphereClosure) {
        performAuthenticatedRequest(completion, "\(project)/orders/\(orderId)")
    }

    public func quickOrder(# product: [String:AnyObject], to address: Address, _ completion: SphereClosure) {
        let currency = address.country == "DE" ? "EUR" : "USD"

        createCart(currency) { (result) in
            result.analysis(ifSuccess: { (cart) in
                self.addProduct(product, quantity: 1, toCart: cart) { (result2) in
                    result2.analysis(ifSuccess: { (cart2) in
                        self.addShippingAddress(address, toCart: cart2) { (result3) in
                            result3.analysis(ifSuccess: { (cart3) in
                                self.createOrder(forCart: cart3, completion)
                            } , ifFailure: { (error) in completion(result: SphereResult(error: error)) })
                        }
                    }, ifFailure: { (error) in completion(result: SphereResult(error: error)) })
                }
            }, ifFailure: { (error) in completion(result: SphereResult(error: error)) })
        }
    }

    public func setPaymentState(state: PaymentState, forOrder order: [String:AnyObject], _ completion: SphereClosure) {
        performAction(["action": "changePaymentState", "paymentState": state.rawValue], onOrder: order, completion)
    }

    public func setState(state: OrderState, forOrder order: [String:AnyObject], _ completion: SphereClosure) {
        performAction(["action": "changeOrderState", "orderState": state.rawValue], onOrder: order, completion)
    }
}
