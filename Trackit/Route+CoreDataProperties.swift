//
//  Route+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 12/4/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//

import Foundation
import CoreData


extension Route {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Route> {
        return NSFetchRequest<Route>(entityName: "Route");
    }

    @NSManaged public var name: String?
    @NSManaged public var startDate: NSDate?
    @NSManaged public var isVisible: Bool
    @NSManaged public var locations: NSSet?

}

// MARK: Generated accessors for locations
extension Route {

    @objc(addLocationsObject:)
    @NSManaged public func addToLocations(_ value: Location)

    @objc(removeLocationsObject:)
    @NSManaged public func removeFromLocations(_ value: Location)

    @objc(addLocations:)
    @NSManaged public func addToLocations(_ values: NSSet)

    @objc(removeLocations:)
    @NSManaged public func removeFromLocations(_ values: NSSet)

}
