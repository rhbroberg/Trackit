//
//  PolyGeofence+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 1/1/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import Foundation
import CoreData


extension PolyGeofence {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PolyGeofence> {
        return NSFetchRequest<PolyGeofence>(entityName: "PolyGeofence");
    }

    @NSManaged public var bounds: NSSet?

}

// MARK: Generated accessors for bounds
extension PolyGeofence {

    @objc(addBoundsObject:)
    @NSManaged public func addToBounds(_ value: Coordinate)

    @objc(removeBoundsObject:)
    @NSManaged public func removeFromBounds(_ value: Coordinate)

    @objc(addBounds:)
    @NSManaged public func addToBounds(_ values: NSSet)

    @objc(removeBounds:)
    @NSManaged public func removeFromBounds(_ values: NSSet)

}
