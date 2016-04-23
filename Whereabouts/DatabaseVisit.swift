
import Foundation
import CoreData
import CoreLocation

class DatabaseVisit: NSManagedObject {

    @NSManaged var totalVisits: NSNumber
    @NSManaged var identifier: String
    @NSManaged var location: CLLocation
    @NSManaged var address: CLPlacemark?
    @NSManaged var horizontalAccuracy: NSNumber
    @NSManaged var arrivalDate: NSDate
    @NSManaged var departureDate: NSDate
    @NSManaged var createdDate: NSDate
    
}

extension DatabaseVisit: Fetchable {
    
    typealias FetchableType = DatabaseVisit
    
    static func entityName() -> String {
        return "Visit"
    }
    
}

