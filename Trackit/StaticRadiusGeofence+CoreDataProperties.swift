//
//  StaticRadiusGeofence+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 1/1/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import Foundation
import CoreData


extension StaticRadiusGeofence {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StaticRadiusGeofence> {
        return NSFetchRequest<StaticRadiusGeofence>(entityName: "StaticRadiusGeofence");
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var radius: Float

}
