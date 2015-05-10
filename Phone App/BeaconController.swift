//
//  BeaconController.swift
//  WatchButton
//
//  Created by Boris Bügling on 10/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import CoreLocation

typealias BeaconCallback = (beacon: Beacon, accuracy: CLLocationAccuracy) -> Void
typealias OutOfRangeCallback = () -> Void

class BeaconController: NSObject, CLLocationManagerDelegate {
    static let estimoteUUID = "B9407F30-F5F8-466E-AFF9-25556B57FE6D"
    lazy var locationManager = CLLocationManager()

    var beaconCallback: BeaconCallback = { (beacon, accuracy) in
        NSLog(String(format:"Beacon: %@, Accuracy: %.2fm", beacon.name, accuracy))
    }
    var outOfRangeCallback: OutOfRangeCallback = { }

    // TODO: Beacons shouldn't be hard-coded
    var beacons = [Beacon(identifier: estimoteUUID, major: 62556, minor: 7826, name: "TestBeacon", uuid: estimoteUUID)]
    
    var regions: [CLBeaconRegion] = [CLBeaconRegion]() {
        didSet {
            self.locationManager.delegate = self
            self.locationManager.requestAlwaysAuthorization()

            self.regions.map({ (region) -> Void in self.locationManager.startRangingBeaconsInRegion(region) })
        }
    }

    func refresh() {
        regions = beacons.map({ (beacon: Beacon) -> CLBeaconRegion in
            //NSLog("Will range beacon %@ with major %@, minor %@", beacon.name, beacon.major, beacon.minor)
            return CLBeaconRegion(proximityUUID: NSUUID(UUIDString: beacon.uuid), major: CLBeaconMajorValue(beacon.major.integerValue), minor: CLBeaconMinorValue(beacon.minor.integerValue), identifier: beacon.identifier)
        })
    }

    func stop() {
        regions.map({ (region) -> Void in self.locationManager.stopRangingBeaconsInRegion(region) })
    }

    // MARK: CLLocationManagerDelegate

    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!,
        inRegion region: CLBeaconRegion!) {
            let beacon = self.beacons[find(regions, region)!]

            let filteredBeacons = (beacons as? [CLBeacon])!.filter({ (beacon: CLBeacon) -> Bool in return beacon.proximity == .Immediate })

            //NSLog("Ranged beacon %@ as Immediate", beacon.name)

            if (filteredBeacons.count > 0) {
                let accuracy = (beacons.first as? CLBeacon)!.accuracy
                beaconCallback(beacon: beacon, accuracy: accuracy)
            } else {
                outOfRangeCallback()
            }
    }
}
