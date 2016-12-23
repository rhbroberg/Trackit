//
//  DynamicGeofence+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 12/23/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension DynamicGeofence {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DynamicGeofence> {
        return NSFetchRequest<DynamicGeofence>(entityName: "DynamicGeofence");
    }

    @NSManaged public var radius: Double

}
