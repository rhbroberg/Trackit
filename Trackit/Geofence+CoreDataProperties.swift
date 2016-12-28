//
//  Geofence+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 12/24/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//

import Foundation
import CoreData


extension Geofence {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Geofence> {
        return NSFetchRequest<Geofence>(entityName: "Geofence");
    }

    @NSManaged public var name: String?
    @NSManaged public var shouldNotify: Bool
    @NSManaged public var notifications: Violation?

}
