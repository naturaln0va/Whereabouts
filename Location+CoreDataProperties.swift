//
//  Location+CoreDataProperties.swift
//  Whereabouts
//
//  Created by Ryan Ackermann on 11/14/15.
//  Copyright © 2015 Ryan Ackermann. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import UIKit.UIColor
import CoreData
import CoreLocation

extension Location {

    @NSManaged var date:  NSDate
    @NSManaged var identifier: String
    @NSManaged var color: UIColor?
    @NSManaged var placemark: CLPlacemark?
    @NSManaged var locationTitle: String
    @NSManaged var location: CLLocation

}
