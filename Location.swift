
import Foundation
import CoreData
import MapKit


class Location: NSManagedObject
{

    var userLocationForAnnotation: CLLocation?
    
    
    func shareableString() -> String
    {
        if let place = placemark {
            return stringFromAddress(place, withNewLine: false)
        }
        else {
            return stringFromCoordinate(location.coordinate)
        }
    }
    
}


extension Location: MKAnnotation
{
    
    var coordinate: CLLocationCoordinate2D {
        return location.coordinate
    }
    
    var title: String? {
        return locationTitle
    }
    
    var subtitle: String? {
        if let userLocation = userLocationForAnnotation {
            let milesAway = userLocation.distanceFromLocation(location) * 0.00062137
            if milesAway > 0.5 {
                let formatter = NSNumberFormatter()
                formatter.minimumFractionDigits = 2
                
                if let formattedMileString = formatter.stringFromNumber(NSNumber(double: milesAway)) {
                    return "\(formattedMileString) mi away"
                }
            }
        }
        return stringFromCoordinate(location.coordinate)
    }
    
}


extension Location: Fetchable
{
    
    typealias FetchableType = Location
    
    static func entityName() -> String
    {
        return "Location"
    }
    
}
