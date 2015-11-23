
import CoreLocation


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

func stringFromCoordinate(coordinate: CLLocationCoordinate2D) -> String
{
    var resultingString = ""
    let coords = [coordinate.latitude, coordinate.longitude]
    
    for coord in coords {
        var seconds = Int(round(fabs(coord * 3600)))
        let degrees = seconds / 3600
        seconds %= 3600
        let minutes = seconds / 60
        seconds %= 60
        
        let cardinal: String
        let first: Bool = resultingString.characters.count == 0
        if first {
            cardinal = coord >= 0 ? "N" : "S"
        }
        else {
            cardinal = coord >= 0 ? "W" : "E"
        }
        resultingString += String(format: "%02i° %02i' %02i\" %@", degrees, minutes, seconds, cardinal)
        resultingString += (first ? ", " : "")
    }
    
    return resultingString
}

func altitudeString(altitude: CLLocationDistance) -> String
{
    if altitude == 0 {
        return "At sea level"
    }
    else {
        let formatter = NSNumberFormatter()
        formatter.minimumFractionDigits = 3
        
        if SettingsController.sharedController.unitStyle {
            let altitudeInYards = altitude / 0.914
            return "\(formatter.stringFromNumber(NSNumber(double: altitudeInYards))!)yrd \(altitudeInYards > 0 ? "above sea level" : "below sea level")"
        }
        else {
            return "\(formatter.stringFromNumber(NSNumber(double: altitude))!)m \(altitude > 0 ? "above sea level" : "below sea level")"
        }
    }
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

func relativeStringForDate(date: NSDate) -> String
{
    let units:NSCalendarUnit = [.Minute, .Hour, .Day, .WeekOfYear, .Month, .Year]
    
    // if "date" is before "now" (i.e. in the past) then the components will be positive
    let components: NSDateComponents = NSCalendar.currentCalendar().components(units, fromDate: date, toDate: NSDate(), options: [])
    
    if components.weekOfYear > 0 {
        return "\(components.weekOfYear)w"
    }
    else if components.day > 0 {
        return "\(components.day)d"
    }
    else {
        if components.hour > 0 {
            return "\(components.hour)h"
        }
        else if components.minute > 1 {
            return "\(components.minute)m"
        }
        else {
            return "now"
        }
    }
}

