
import Foundation
import CoreLocation
import MapKit

class Visit: NSObject {
    
    var totalVisits: Int
    var identifier: String
    var coordinate: CLLocationCoordinate2D
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
    
    var location: CLLocation {
        return CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: kCLLocationAccuracyBest, verticalAccuracy: kCLLocationAccuracyBest, timestamp: arrivalDate)
    }
    
    init(dbVisit: DatabaseVisit) {
        totalVisits = dbVisit.totalVisits
        identifier = dbVisit.identifier
        coordinate = dbVisit.coordinate
        address = dbVisit.address
        horizontalAccuracy = dbVisit.horizontalAccuracy
        arrivalDate = dbVisit.arrivalDate
        departureDate = dbVisit.departureDate
        
        super.init()
    }
    
    init(visit: CLVisit) {
        identifier = "\(NSUUID().UUIDString)+\(visit.hashValue)+\(visit.arrivalDate.hashValue)+\(visit.departureDate.hashValue)"
        totalVisits = 1
        coordinate = visit.coordinate
        horizontalAccuracy = visit.horizontalAccuracy
        arrivalDate = visit.arrivalDate
        departureDate = visit.departureDate
        
        super.init()
    }
    
}

extension Visit: MKAnnotation {
    
    var title: String? {
        return (totalVisits == 1 ? "Visited on: " : "\(totalVisits) since ") + dateFormatter.stringFromDate(arrivalDate)
    }
    
    var subtitle: String? {
        return address != nil ? stringFromAddress(address!, withNewLine: true) : stringFromCoordinate(coordinate)
    }
    
}