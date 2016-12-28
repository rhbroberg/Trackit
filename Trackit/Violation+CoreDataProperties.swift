//
//  Violation+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 12/24/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//

import Foundation
import CoreData


extension Violation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Violation> {
        return NSFetchRequest<Violation>(entityName: "Violation");
    }

    @NSManaged public var name: String?
    @NSManaged public var geofence: Geofence?
    @NSManaged public var location: Location?

}
