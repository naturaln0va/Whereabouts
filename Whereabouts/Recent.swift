//
//  Recent.swift
//  Whereabouts
//
//  Created by Ryan Ackermann on 10/22/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

import Foundation
import CoreLocation

class Recent {
    
    let placemark: CLPlacemark!
    let timeStamp: NSDate!
    
    init(placemark: CLPlacemark, timeStamp: NSDate) {
        self.placemark = placemark
        self.timeStamp = timeStamp
    }
    
    func filteredFare() -> String {
        return ""
    }
    
    func shortLocationDescription() -> String {
        if placemark.areasOfInterest != nil {
            return "\(placemark.areasOfInterest), \(placemark.administrativeArea)"
        } else {
            return "\(placemark.locality), \(placemark.administrativeArea)"
        }
    }
    
    func longLocationDescription() -> String {
        return "\(placemark.subThoroughfare) \(placemark.thoroughfare) \n \(placemark.locality), \(placemark.administrativeArea), \(placemark.postalCode)"
    }    
}