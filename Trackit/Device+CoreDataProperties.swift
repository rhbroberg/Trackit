//
//  Device+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 12/4/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//

import Foundation
import CoreData


extension Device {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Device> {
        return NSFetchRequest<Device>(entityName: "Device");
    }

    @NSManaged public var id: Int16
    @NSManaged public var name: String?
    @NSManaged public var locations: NSSet?

}

// MARK: Generated accessors for locations
extension Device {

    @objc(addLocationsObject:)
    @NSManaged public func addToLocations(_ value: Location)

    @objc(removeLocationsObject:)
    @NSManaged public func removeFromLocations(_ value: Location)

    @objc(addLocations:)
    @NSManaged public func addToLocations(_ values: NSSet)

    @objc(removeLocations:)
    @NSManaged public func removeFromLocations(_ values: NSSet)

}
