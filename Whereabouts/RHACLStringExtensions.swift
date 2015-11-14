//
//  Created by Ryan Ackermann on 5/30/15.
//  Copyright (c) 2015 Ryan Ackermann. All rights reserved.
//

import CoreLocation

func stringFromAddress(placemark: CLPlacemark) -> String
{
    var line1 = ""
    var line2 = ""
    
    if let s = placemark.subThoroughfare {
        line1 += s + " "
    }
    
    if let s = placemark.thoroughfare {
        line1 += s
    }
    
    if let s = placemark.locality {
        line2 += s + " "
    }
    
    if let s = placemark.administrativeArea {
        line2 += s + " "
    }
    
    if let s = placemark.postalCode {
        line2 += s
    }
    
    if line1.characters.count > 0 && line2.characters.count > 0 {
        return line1 + "\n" + line2
    }
    else if line1.characters.count > 0 {
        return line1
    }
    else if line2.characters.count > 0 {
        return line2
    }
    else {
        return "Invalid Address"
    }
}

func shortLocationDescription(placemark: CLPlacemark) -> String
{
    if placemark.areasOfInterest != nil {
        return "\(placemark.areasOfInterest!.first!) \(placemark.administrativeArea)"
    }
    else {
        return "\(placemark.locality) \(placemark.administrativeArea)"
    }
}

func longLocationDescription(placemark: CLPlacemark) -> String
{
    return "\(placemark.subThoroughfare) \(placemark.thoroughfare) \(placemark.locality), \(placemark.administrativeArea) \(placemark.postalCode)"
}

func detailLocationDescription(placemark: CLPlacemark) -> String
{
    if let subFare = placemark.subThoroughfare {
        if let fare = placemark.thoroughfare {
            return "\(subFare) \(fare)"
        }
        return "\(subFare)"
    }
    else {
        if let fare = placemark.thoroughfare {
            return "\(fare)"
        }
        return ""
    }
}

func sharableStringFrom(placemark: CLPlacemark) -> String
{
    return "\(placemark.subThoroughfare) \(placemark.thoroughfare) \(placemark.locality), \(placemark.administrativeArea)"
}

func stringFromCoordinate(coordinate: CLLocationCoordinate2D) -> String
{
    var resultingString = ""
    let coords = [coordinate.latitude, coordinate.longitude]
    
    for coord in coords {
        let degrees = Int(coord)
        let minutes = Int((coord - Double(degrees)) * 100)
        let seconds = Int((((coord - Double(degrees)) * 100) - Double(minutes)) * 100)
        let cardinal: Character
        let first: Bool = resultingString.characters.count <= 0
        if first {
            cardinal = degrees > 0 ? "N" : "S"
        }
        else {
            cardinal = degrees > 0 ? "W" : "E"
        }
        resultingString = resultingString + "\(degrees)º\(minutes)'\(seconds)'' \(cardinal)"
        resultingString = resultingString + (first ? ", " : "")
    }
    
    return resultingString
}

func relativeStringForDate(date: NSDate) -> String
{
    let units:NSCalendarUnit = [.Minute, .Hour, .Day, .WeekOfYear, .Month, .Year]
    
    // if "date" is before "now" (i.e. in the past) then the components will be positive
    let components: NSDateComponents = NSCalendar.currentCalendar().components(units, fromDate: date, toDate: NSDate(), options: [])
    
    if components.weekOfYear > 0 {
        return "\(components.weekOfYear) w"
    }
    else if components.day > 0 {
        return "\(components.day) d"
    }
    else {
        if components.hour > 0 {
            return "\(components.hour) h"
        }
        else if components.minute > 1 {
            return "\(components.minute) m"
        }
        else {
            return "now"
        }
    }
}

