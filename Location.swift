
import Foundation
import CoreData
import MapKit


class Location: NSManagedObject
{

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
