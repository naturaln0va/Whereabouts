
import UIKit
import CloudKit
import MapKit

struct CloudLocation {
    
    static let recordType = "Location"
    
    enum CloudKeys: String {
        case CreatedDate = "createdDate"
        case Color = "colorString"
        case Identifier = "identifier"
        case Location = "location"
        case Title = "locationTitle"
        case MapItem = "mapItem"
        case Place = "place"
    }
    
    let color: String
    let createdDate: NSDate
    let identifier: String
    let location: CLLocation
    let title: String
    
    private(set) var mapItem: MKMapItem? = nil
    private(set) var place: CLPlacemark? = nil
    
    var record: CKRecord {
        let record = CKRecord(recordType: "Location")
        
        record[CloudKeys.Color.rawValue] = color
        record[CloudKeys.CreatedDate.rawValue] = createdDate
        record[CloudKeys.Identifier.rawValue] = identifier
        record[CloudKeys.Location.rawValue] = location
        record[CloudKeys.Title.rawValue] = title
        
        if let mapItem = mapItem {
            record[CloudKeys.MapItem.rawValue] = NSKeyedArchiver.archivedDataWithRootObject(mapItem)
        }
        if let place = place {
            record[CloudKeys.Place.rawValue] = NSKeyedArchiver.archivedDataWithRootObject(place)
        }
        
        return record
    }
    
    init(record: CKRecord) {
        color = record[CloudKeys.Color.rawValue] as? String ?? ""
        createdDate = record[CloudKeys.CreatedDate.rawValue] as! NSDate
        identifier = record[CloudKeys.Identifier.rawValue] as? String ?? ""
        location = record[CloudKeys.Location.rawValue] as! CLLocation
        title = record[CloudKeys.Title.rawValue] as? String ?? ""
        
        if let mapData = record[CloudKeys.MapItem.rawValue] as? NSData {
            mapItem = NSKeyedUnarchiver.unarchiveObjectWithData(mapData) as? MKMapItem
        }
        if let placemarkData = record[CloudKeys.Place.rawValue] as? NSData {
            place = NSKeyedUnarchiver.unarchiveObjectWithData(placemarkData) as? CLPlacemark
        }
    }
    
    init(localLocation: Location) {
        color = localLocation.color?.hexString(false) ?? ""
        createdDate = localLocation.date
        identifier = localLocation.identifier
        location = localLocation.location
        title = localLocation.locationTitle
        mapItem = localLocation.mapItem
        place = localLocation.placemark
    }
    
}
