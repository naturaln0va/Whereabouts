
import Foundation
import CoreData
import MapKit


class Location: NSManagedObject
{

    var distanceAndETAString: String?
    
    
    func shareableString() -> String
    {
        var shareString = ""
        
        if let title = title {
            shareString += title + "\n"
        }
        
        if let place = placemark {
            shareString += stringFromAddress(place, withNewLine: false)
        }
        else {
            shareString += stringFromCoordinate(location.coordinate)
        }
        
        shareString += "\nvia Whereabouts: (http://appstore.com/whereaboutslocationutility)"
        
        return shareString
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
        if let distanceString = distanceAndETAString {
            return distanceString
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
