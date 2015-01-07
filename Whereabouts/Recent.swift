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
    
    func shortLocationDescription(placemark: CLPlacemark) -> String {
        if placemark.areasOfInterest != nil {
            return "\(placemark.areasOfInterest), \(placemark.administrativeArea)"
        } else {
            return "\(placemark.locality), \(placemark.administrativeArea)"
        }
    }
    
    func longLocationDescription(placemark: CLPlacemark) -> String {
        return "\(placemark.subThoroughfare) \(placemark.thoroughfare), \(placemark.locality), \(placemark.administrativeArea), \(placemark.postalCode)"
    }
    
    func relativeStringForDate(date: NSDate) -> String {
        let units:NSCalendarUnit = .CalendarUnitMinute | .CalendarUnitHour | .CalendarUnitDay | .CalendarUnitWeekOfYear |
            .CalendarUnitMonth | .CalendarUnitYear
        
        // if "date" is before "now" (i.e. in the past) then the components will be positive
        let components: NSDateComponents = NSCalendar.currentCalendar().components(units, fromDate: date, toDate: NSDate(), options: nil)
        
        if components.year > 0 {
            return "\(components.year) years ago"
        } else if components.month > 0 {
            if components.month > 1 {
                return "\(components.month) months ago"
            } else {
                return "Last month"
            }
        } else if components.weekOfYear > 0 {
            if components.weekOfYear > 1 {
                return "\(components.weekOfYear) weeks ago"
            } else {
                return "Last week"
            }
        } else if components.day > 0 {
            if components.day > 1 {
                return "\(components.day) days ago"
            } else {
                return "Yesterday"
            }
        } else {
            if components.hour > 0 {
                if components.hour > 1 {
                    return "\(components.hour) hours ago"
                } else {
                    return "1 hour ago"
                }
            } else if components.minute > 1 {
                if components.minute == 1 {
                    return "\(components.minute) minuts ago"
                } else {
                    return "1 minute ago"
                }
            } else {
                return "A moment ago"
            }
        }
    }
}