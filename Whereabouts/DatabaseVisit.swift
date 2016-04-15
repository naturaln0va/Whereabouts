
import Foundation
import CoreData
import CoreLocation

class DatabaseVisit: NSManagedObject {

    @NSManaged var totalVisits: Int
    @NSManaged var identifier: String
    @NSManaged var coordinate: CLLocationCoordinate2D
    @NSManaged var address: CLPlacemark?
    @NSManaged var horizontalAccuracy: Double
    @NSManaged var arrivalDate: NSDate
    @NSManaged var departureDate: NSDate
    
}

extension DatabaseVisit: Fetchable {
    
    typealias FetchableType = DatabaseVisit
    
    static func entityName() -> String {
        return "Visit"
    }
    
}

