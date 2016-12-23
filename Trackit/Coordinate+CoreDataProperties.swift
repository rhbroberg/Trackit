//
//  Coordinate+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 12/23/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Coordinate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Coordinate> {
        return NSFetchRequest<Coordinate>(entityName: "Coordinate");
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longtitude: Double

}
