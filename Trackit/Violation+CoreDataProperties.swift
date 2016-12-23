//
//  Violation+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 12/23/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Violation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Violation> {
        return NSFetchRequest<Violation>(entityName: "Violation");
    }

    @NSManaged public var name: String?
    @NSManaged public var location: Location?
    @NSManaged public var geofence: Geofence?

}
