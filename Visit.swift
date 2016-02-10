
import Foundation
import CoreData
import MapKit


class Visit: NSManagedObject
{
    
    private lazy var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "EEEE MMM d"
        return formatter
    }()
    
    var location: CLLocation {
        return CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: kCLLocationAccuracyBest, verticalAccuracy: kCLLocationAccuracyBest, timestamp: arrivalDate)
    }
    
}


extension Visit: MKAnnotation
{
    
    var coordinate: CLLocationCoordinate2D {
        return locationCoordinate.coordinate
    }
    
    var title: String? {
        return "Visited on: " + dateFormatter.stringFromDate(arrivalDate)
    }
    
    var subtitle: String? {
        return stringFromCoordinate(locationCoordinate.coordinate)
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

