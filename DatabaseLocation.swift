
import Foundation
import CoreData
import MapKit

class DatabaseLocation: NSManagedObject {
    
    @NSManaged var date: NSDate
    @NSManaged var identifier: String
    @NSManaged var color: String?
    @NSManaged var placemark: CLPlacemark?
    @NSManaged var locationTitle: String?
    @NSManaged var textContent: String?
    @NSManaged var location: CLLocation
    @NSManaged var itemName: String?
    @NSManaged var itemPhoneNumber: String?
    @NSManaged var itemWebLink: String?
    @NSManaged var cloudRecordIdentifierData: NSData?
    
}

extension DatabaseLocation: Fetchable {
    typealias FetchableType = DatabaseLocation
    
    static func entityName() -> String {
        return "Location"
    }
}
