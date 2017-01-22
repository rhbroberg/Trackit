//
//  Device+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 1/22/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import Foundation
import CoreData


extension Device {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Device> {
        return NSFetchRequest<Device>(entityName: "Device");
    }

    @NSManaged public var color: String?
    @NSManaged public var firmware: String?
    @NSManaged public var icci: String?
    @NSManaged public var id: Int16
    @NSManaged public var imei: String?
    @NSManaged public var imsi: String?
    @NSManaged public var name: String?
    @NSManaged public var software: String?
    @NSManaged public var version: String?
    @NSManaged public var locations: NSSet?
    @NSManaged public var violations: Violation?

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
