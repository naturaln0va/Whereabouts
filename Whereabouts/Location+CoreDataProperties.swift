//
//  Location+CoreDataProperties.swift
//  Whereabouts
//
//  Created by Ryan Ackermann on 9/21/15.
//  Copyright © 2015 Ryan Ackermann. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import UIKit
import CoreData
import CoreLocation

extension Location {

    @NSManaged var date: NSDate
    @NSManaged var placemark: CLPlacemark?
    @NSManaged var color: UIColor?
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var title: String?

}
