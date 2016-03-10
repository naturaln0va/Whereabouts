
import Foundation
import CoreData
import MapKit


class Visit: NSManagedObject
{
    
    private lazy var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        formatter.dateStyle = .MediumStyle
        return formatter
    }()
    
    var location: CLLocation {
        return CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: kCLLocationAccuracyBest, verticalAccuracy: kCLLocationAccuracyBest, timestamp: arrivalDate)
    }
    
}


extension Visit: MKAnnotation
{
    
    var title: String? {
        return (totalVisits == 1 ? "Visited on: " : "\(totalVisits) since ") + dateFormatter.stringFromDate(arrivalDate)
    }
    
    var subtitle: String? {
        return address != nil ? stringFromAddress(address!, withNewLine: true) : stringFromCoordinate(coordinate)
    }
    
}


extension Visit: Fetchable
{
    
    typealias FetchableType = Visit
    
    static func entityName() -> String
    {
        return "Visit"
    }
    
}

