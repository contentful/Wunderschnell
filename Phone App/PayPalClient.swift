//
//  PayPalClient.swift
//  WatchButton
//
//  Created by Boris Bügling on 09/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Alamofire

// Somehow using `NSURLAuthenticationChallenge` didn't work against the PayPal API, either 😭
private struct AuthRequest: URLRequestConvertible {
    private let clientId: String
    private let clientSecret: String
    private let futurePaymentCode: String

    var URLRequest: NSURLRequest {
        if let URL = NSURL(string: "https://api.sandbox.paypal.com/v1/oauth2/token") {
            let URLRequest = NSMutableURLRequest(URL: URL)
            URLRequest.HTTPMethod = Method.POST.rawValue

            let parameters = [ "grant_type": "authorization_code", "response_type": "token", "redirect_uri": "urn:ietf:wg:oauth:2.0:oob", "code": futurePaymentCode ]

            let auth = String(format: "%@:%@", clientId, clientSecret).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
            let header = auth.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
            URLRequest.setValue("Basic \(header)", forHTTPHeaderField: "Authorization")

            let encoding = Alamofire.ParameterEncoding.URL
            return encoding.encode(URLRequest, parameters: parameters).0
        }

        fatalError("Broken Authentication URL...")
    }
}

// Implementation of https://github.com/paypal/PayPal-iOS-SDK/blob/master/docs/future_payments_server.md because we want no server. 😎
public class PayPalClient {
    let baseURL = "https://api.sandbox.paypal.com/v1"
    let clientId: String
    let clientSecret: String
    let futurePaymentCode: String
    let metadataId: String
    var token: String?

    public init(clientId: String, clientSecret: String, futurePaymentCode: String, metadataId: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.futurePaymentCode = futurePaymentCode
        self.metadataId = metadataId
    }

    private func createActualPayment(description: String, _ currency: String, _ amount: String, _ completion: (paymentId: String) -> Void) {
        let parameters: [String:AnyObject] = [ "intent":"authorize", "payer":["payment_method":"paypal"], "transactions": [ [ "amount": [ "currency": currency, "total": amount ], "description":  description ] ]]

        Alamofire.request(payPalRequest("payments/payment", .POST, parameters))
            .responseJSON { (_, _, JSON, _) in
                if let JSON = JSON as? [String:AnyObject], transactions = JSON["transactions"] as? [[String:AnyObject]], relatedResources = transactions.first?["related_resources"] as? [[String:AnyObject]], authorization = relatedResources.first?["authorization"] as? [String:AnyObject], id = authorization["id"] as? String {
                    completion(paymentId: id)
                } else {
                    NSLog("Did not receive ID for payment")
                }
            }
    }

    private func payPalRequest(endpoint: String, _ method: Alamofire.Method, _ parameters: [String: AnyObject]?) -> URLRequestConvertible {
        assert(token != nil, "")

        if let token = token, URL = NSURL(string: "\(baseURL)/\(endpoint)") {
            let URLRequest = NSMutableURLRequest(URL: URL)
            URLRequest.HTTPMethod = method.rawValue

            URLRequest.setValue(metadataId, forHTTPHeaderField: "PayPal-Client-Metadata-Id")
            URLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let encoding = Alamofire.ParameterEncoding.JSON
            return encoding.encode(URLRequest, parameters: parameters).0
        }

        fatalError("Could not create valid request.")
    }

    public func createPayment(description: String, _ currency: String, _ amount: String, completion: (paymentId: String) -> Void) {
        Alamofire.request(AuthRequest(clientId: clientId, clientSecret: clientSecret, futurePaymentCode: futurePaymentCode))
            .authenticate(user: clientId, password: clientSecret)
            .responseJSON { (_, _, JSON, _) in
                if let JSON = JSON as? [String:AnyObject] {
                    if let token = JSON["access_token"] as? String {
                        self.token = token
                        self.createActualPayment(description, currency, amount, completion)
                    } else {
                        NSLog("No `access_token` received: %@", JSON)
                    }
                }
            }
    }

    public func pay(paymentId: String, _ currency: String, _ amount: String, completion: (paid: Bool) -> Void) {
        // FIXME: In the actual thing, we would need to refresh the OAuth token.

        let URL = "payments/authorization/\(paymentId)/capture"
        let parameters: [String: AnyObject] = [ "amount": [ "currency": currency, "total": amount ], "is_final_capture": true]

        Alamofire.request(payPalRequest(URL, .POST, parameters))
            .responseJSON { (_, _, JSON, _) in
                if let JSON = JSON as? [String:AnyObject], amount = JSON["amount"] as? [String:AnyObject] {
                    completion(paid: true)
                } else {
                    completion(paid: false)
                }
            }
    }
}
