//
//  Geofence+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 12/23/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//  This file was automatically generated and should not be edited.
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
