//
//  StaticRadiusGeofence+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 12/23/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension StaticRadiusGeofence {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StaticRadiusGeofence> {
        return NSFetchRequest<StaticRadiusGeofence>(entityName: "StaticRadiusGeofence");
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var radius: Double

}
