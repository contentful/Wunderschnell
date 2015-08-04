//
//  ViewController.swift
//  WatchButton
//
//  Created by Boris Bügling on 09/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Alamofire
import Cube
import Keys
import MBProgressHUD
import UIKit

class ViewController: UIViewController, PayPalFuturePaymentDelegate {
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var productImageView: UIImageView!

    private var payPalConfiguration: PayPalConfiguration!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Not that pretty -- but that way we localized the Sphere.IO interactions for now
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            delegate.fetchSelectedProduct() {
                if let productData = delegate.selectedProduct {
                    let product = Product(productData)

                    self.descriptionLabel.text = product.productDescription
                    self.nameLabel.text = product.name

                    if let amount = product.price["amount"], currency = product.price["currency"] {
                        self.priceLabel.text = "\(amount) \(currency)"
                    }

                    Alamofire.request(.GET, product.imageUrl).response() { (_, _, data, error) in
                        if let data = data {
                            self.productImageView.image = UIImage(data: data)
                        }
                    }
                }
                return
            }
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        PayPalMobile.preconnectWithEnvironment(PayPalEnvironmentSandbox)
    }

    // MARK: - Actions
    @IBAction private func dismissForm() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func setUpAddressTapped(sender: UIBarButtonItem) {
        let vc = AddressFormViewController()
        vc.navigationItem.title = "Personal"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "dismissForm")
        
        presentViewController(UINavigationController(rootViewController: vc), animated: true) { }
    }

    @IBAction func setUpPaymentTapped(sender: UIBarButtonItem) {
        payPalConfiguration = PayPalConfiguration()

        payPalConfiguration.merchantName = "Ultramagnetic Omega Supreme"
        payPalConfiguration.merchantPrivacyPolicyURL = NSURL(string:"https://www.omega.supreme.example/privacy")
        payPalConfiguration.merchantUserAgreementURL = NSURL(string:"https://www.omega.supreme.example/user_agreement")

        let vc = PayPalFuturePaymentViewController(configuration: payPalConfiguration, delegate: self)
        presentViewController(vc, animated: true, completion: nil)
    }

    // MARK: - PayPalFuturePaymentDelegate

    func payPalFuturePaymentDidCancel(futurePaymentViewController: PayPalFuturePaymentViewController!) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func payPalFuturePaymentViewController(futurePaymentViewController: PayPalFuturePaymentViewController!, didAuthorizeFuturePayment futurePaymentAuthorization: [NSObject : AnyObject]!) {
        dismissViewControllerAnimated(true, completion: nil)
        MBProgressHUD.showHUDAddedTo(view, animated: true)

        if let futurePaymentAuthorization = futurePaymentAuthorization {
            let clientMetadataId = PayPalMobile.clientMetadataID()

            if let response = futurePaymentAuthorization["response"] as? [String:AnyObject], code = response["code"] as? String {
                let keys = WatchbuttonKeys()
                let client = PayPalClient(clientId: keys.payPalSandboxClientId(), clientSecret: keys.payPalSandboxClientSecret(), code: code, metadataId: clientMetadataId)

                if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate, productData = delegate.selectedProduct {
                    let product = Product(productData)

                    if let amount = product.price["amount"], currency = product.price["currency"] {
                        client.createPayment(product.name, currency, amount) { (paymentId) in
                            storePaymentId(paymentId)
                            storeRefreshToken(client.refreshToken!)
                            NSLog("Stored payment ID \(paymentId) in keychain.")

                            MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                        }

                        return
                    }
                }
            }
        }

        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
    }
}
