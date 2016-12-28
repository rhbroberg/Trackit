//
//  Location+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 12/24/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location");
    }

    @NSManaged public var altitude: Float
    @NSManaged public var course: Float
    @NSManaged public var id: Int64
    @NSManaged public var latitude: Float
    @NSManaged public var longitude: Float
    @NSManaged public var satellites: Int64
    @NSManaged public var signal: Int64
    @NSManaged public var speed: Float
    @NSManaged public var timestamp: NSDate?
    @NSManaged public var device: Device?
    @NSManaged public var notification: Violation?
    @NSManaged public var route: Route?

}
