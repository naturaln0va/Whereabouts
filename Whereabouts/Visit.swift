
import Foundation
import CoreLocation
import MapKit

class Visit: NSObject {
    
    let identifier: String
    let location: CLLocation
    
    var totalVisits: Int = 0
    var address: CLPlacemark?
    var horizontalAccuracy: Double
    var arrivalDate: NSDate
    var departureDate: NSDate
    
    private lazy var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        formatter.dateStyle = .MediumStyle
        return formatter
    }()
    
    init(dbVisit: DatabaseVisit) {
        totalVisits = dbVisit.totalVisits.integerValue
        identifier = dbVisit.identifier
        location = dbVisit.location
        address = dbVisit.address
        horizontalAccuracy = dbVisit.horizontalAccuracy.doubleValue
        arrivalDate = dbVisit.arrivalDate
        departureDate = dbVisit.departureDate
        
        super.init()
    }
    
    init(location: CLLocation) {
        self.location = location
        identifier = "\(NSDate().hashValue)+\(location.coordinate.latitude)+\(location.coordinate.longitude)"
        totalVisits = 1
        horizontalAccuracy = 0.0
        arrivalDate = NSDate.distantPast()
        departureDate = NSDate.distantFuture()
    }
    
    init(visit: CLVisit) {
        identifier = "\(NSUUID().UUIDString)+\(visit.hashValue)+\(visit.arrivalDate.hashValue)+\(visit.departureDate.hashValue)"
        totalVisits = 1
        location = CLLocation(coordinate: visit.coordinate, altitude: 0, horizontalAccuracy: visit.horizontalAccuracy, verticalAccuracy: 0, timestamp: NSDate())
        horizontalAccuracy = visit.horizontalAccuracy
        arrivalDate = visit.arrivalDate
        departureDate = visit.departureDate
        
        super.init()
    }
    
}

extension Visit: MKAnnotation {
    
    var title: String? {
        return address != nil ? stringFromAddress(address!, withNewLine: true) : coordinate.formattedString()
    }
    
    var subtitle: String? {
        return (totalVisits == 1 ? "Visited on: " : "\(totalVisits) since ") + dateFormatter.stringFromDate(arrivalDate)
    }
    
    var coordinate: CLLocationCoordinate2D {
        return location.coordinate
    }
    
}
