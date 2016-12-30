//
//  MeasuredFence.swift
//  Trackit
//
//  Created by Richard Broberg on 12/29/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//

import Foundation
import CoreLocation

protocol MeasuredFence {
    func within(bounds: CLLocation) -> Bool
}

extension Geofence : MeasuredFence {
    func within(bounds: CLLocation) -> Bool {
        return true
    }
}

extension DynamicGeofence : CLLocationManagerDelegate {
    override func within(bounds: CLLocation) -> Bool {
        print("dynamic within called")
        let locationManager = CLLocationManager()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            if let whereIAm = locationManager.location {
                let targetDistance = whereIAm.distance(from: bounds)
                let difference = targetDistance.subtracting(Double(radius))
                print("i am here: \(whereIAm.coordinate) which is \(targetDistance) from \(bounds) where radius is \(radius) and difference is \(difference)")
                if difference > 0 {
                    return false
                }
            }
        }

        return true
    }
}

