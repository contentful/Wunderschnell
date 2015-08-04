//
//  GlanceController.swift
//  WatchButton WatchKit Extension
//
//  Created by Boris Bügling on 09/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Foundation
import MMWormhole
import WatchConnectivity
import WatchKit

class GlanceController: WKInterfaceController {
    let wormhole = MMWormhole(applicationGroupIdentifier: AppGroupIdentifier, optionalDirectory: DirectoryIdentifier)

    @IBOutlet weak var infoLabel: WKInterfaceLabel!

    func resetLabel() {
        infoLabel.setText("No beacons in range :(")
    }

    override func willActivate() {
        super.willActivate()
        
        resetLabel()
        wormhole.listenForMessageWithIdentifier(Reply.BeaconRanged.rawValue) { (data) in
            if let ranged = data as? Bool {
                if ranged {
                    self.infoLabel.setText("Beacon in range, tap to buy.")
                }
                return
            }

            self.resetLabel()
        }

        WCSession.defaultSession().sendMessage([ CommandIdentifier: Command.Nothing.rawValue ], replyHandler: { (_) in
        }, errorHandler: nil)
    }
}
