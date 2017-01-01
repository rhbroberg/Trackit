//
//  Geofence+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 1/1/17.
//  Copyright © 2017 Brobasino. All rights reserved.
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
