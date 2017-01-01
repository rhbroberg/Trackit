//
//  DynamicGeofence+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 1/1/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import Foundation
import CoreData


extension DynamicGeofence {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DynamicGeofence> {
        return NSFetchRequest<DynamicGeofence>(entityName: "DynamicGeofence");
    }

    @NSManaged public var radius: Float

}
