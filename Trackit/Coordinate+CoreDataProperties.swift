//
//  Coordinate+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 1/1/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import Foundation
import CoreData


extension Coordinate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Coordinate> {
        return NSFetchRequest<Coordinate>(entityName: "Coordinate");
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longtitude: Double
    @NSManaged public var polygon: PolyGeofence?

}
