//
//  StaticRadiusGeofence+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 12/24/16.
//  Copyright © 2016 Brobasino. All rights reserved.
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
