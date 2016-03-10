//
//  Visit+CoreDataProperties.swift
//  Whereabouts
//
//  Created by Ryan Ackermann on 12/11/15.
//  Copyright © 2015 Ryan Ackermann. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData
import CoreLocation

extension Visit {

    @NSManaged var totalVisits: Int
    @NSManaged var identifier: String
    @NSManaged var coordinate: CLLocationCoordinate2D
    @NSManaged var address: CLPlacemark?
    @NSManaged var horizontalAccuracy: Double
    @NSManaged var arrivalDate: NSDate
    @NSManaged var departureDate: NSDate

}
