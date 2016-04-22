
import Foundation
import MapKit

class DroppedAnnotation: NSObject {
    
    let location: Location
    
    init(location: Location) {
        self.location = location
        super.init()
    }
    
}

extension DroppedAnnotation: MKAnnotation {
    
    var title: String? {
        return "Dropped Pin"
    }
    
    var subtitle: String? {
        if let place = location.placemark {
            return place.fullFormatedString()
        }
        else {
            return location.coordinate.formattedString()
        }
    }
    
    var coordinate: CLLocationCoordinate2D {
        return location.coordinate
    }
    
}