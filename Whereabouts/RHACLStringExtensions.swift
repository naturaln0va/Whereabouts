
import CoreLocation
import MapKit


func stringFromAddress(placemark: CLPlacemark, withNewLine newline: Bool) -> String
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
        return line1 + (newline ? "\n" : " ") + line2
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

func altitudeString(altitude: CLLocationDistance) -> String
{
    if altitude == 0 {
        return "At sea level"
    }
    else {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .Abbreviated
        
        let altInFeet = Int(altitude * 3.2808399)
        let altString = altInFeet >= 5280 ? formatter.stringFromDistance(altitude) : "\(altInFeet)ft"
        
        return "\(altString) \(altitude > 0 ? "above sea level" : "below sea level")"
    }
}

func distanceString(distanceInMeters: CLLocationDistance) -> String
{
    let formatter = MKDistanceFormatter()
    formatter.unitStyle = .Abbreviated
    return formatter.stringFromDistance(distanceInMeters)
}

func timeStringFromSeconds(interval: NSTimeInterval) -> String
{
    let now = NSDate()
    let future = NSDate(timeInterval: interval, sinceDate: now)
    
    let units: NSCalendarUnit = [.Minute, .Hour, .Day]
    let components = NSCalendar.currentCalendar().components(units, fromDate: now, toDate: future, options: .MatchNextTime)
    
    var intervalString: String = ""
    if components.day > 0 {
        if components.day == 1 {
            intervalString += "\(components.day) day, "
        }
        else {
            intervalString += "\(components.day) days, "
        }
    }
    if components.hour > 0 {
        if components.hour == 1 {
            intervalString += "\(components.hour) hour, "
        }
        else {
            intervalString += "\(components.hour) hours, "
        }
    }
    if components.minute > 0 {
        if components.minute == 1 {
            intervalString += "\(components.minute) minute"
        }
        else {
            intervalString += "\(components.minute) minutes"
        }
    }
    
    return intervalString
}
