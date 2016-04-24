
import Foundation

extension NSTimeInterval {
    
    func relativeString() -> String {
        let now = NSDate()
        let future = NSDate(timeInterval: self, sinceDate: now)
        
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
    
}
