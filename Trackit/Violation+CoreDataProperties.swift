//
//  Violation+CoreDataProperties.swift
//  Trackit
//
//  Created by Richard Broberg on 1/22/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import Foundation
import CoreData


extension Violation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Violation> {
        return NSFetchRequest<Violation>(entityName: "Violation");
    }

    @NSManaged public var acknowledged: NSDate?
    @NSManaged public var name: String?
    @NSManaged public var device: Device?
    @NSManaged public var geofence: Geofence?
    @NSManaged public var location: Location?

}
