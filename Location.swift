
import Foundation
import CoreData
import MapKit


class Location: NSManagedObject {
    
    var shareableString: String {
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

extension Location {
    
    @NSManaged var date: NSDate
    @NSManaged var identifier: String
    @NSManaged var color: UIColor?
    @NSManaged var placemark: CLPlacemark?
    @NSManaged var locationTitle: String
    @NSManaged var location: CLLocation
    
}

extension Location: MKAnnotation {
    
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

extension Location: Fetchable {
    
    typealias FetchableType = Location
    
    static func entityName() -> String {
        return "Location"
    }
    
}
