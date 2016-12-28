//
//  DynamicGeofence+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 12/24/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//

import Foundation
import CoreData


extension DynamicGeofence {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DynamicGeofence> {
        return NSFetchRequest<DynamicGeofence>(entityName: "DynamicGeofence");
    }

    @NSManaged public var radius: Float

}
