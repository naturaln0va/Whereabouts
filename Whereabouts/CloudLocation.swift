
import UIKit
import CloudKit
import MapKit

struct CloudLocation {
    
    static let recordType = "Location"
    
    enum CloudKeys: String {
        case CreatedDate = "created_date"
        case Identifier = "identifier"
        case Location = "location"
        case Title = "location_title"
        case Content = "text_content"
        case Place = "place"
        case ItemName = "item_name"
        case ItemNumber = "item_number"
        case ItemLink = "item_link"
    }
    
    let createdDate: NSDate
    let identifier: String
    let location: CLLocation
    
    private(set) var recordID: CKRecordID? = nil
    private(set) var place: CLPlacemark? = nil
    private(set) var locationTitle: String? = nil
    private(set) var textContent: String? = nil
    private(set) var itemName: String? = nil
    private(set) var itemPhoneNumber: String? = nil
    private(set) var itemWebLink: String? = nil
    
    var record: CKRecord {
        
        let record: CKRecord
        
        if let recordID = recordID {
            record = CKRecord(recordType: "Location", recordID: recordID)
        }
        else {
            record = CKRecord(recordType: "Location")
        }

        record[CloudKeys.CreatedDate.rawValue] = createdDate
        record[CloudKeys.Identifier.rawValue] = identifier
        record[CloudKeys.Location.rawValue] = location
        record[CloudKeys.Title.rawValue] = locationTitle
        record[CloudKeys.Content.rawValue] = textContent
        record[CloudKeys.ItemName.rawValue] = itemName
        record[CloudKeys.ItemNumber.rawValue] = itemPhoneNumber
        record[CloudKeys.ItemLink.rawValue] = itemWebLink
        
        if let place = place {
            record[CloudKeys.Place.rawValue] = NSKeyedArchiver.archivedDataWithRootObject(place)
        }
        
        return record
    }
    
    init(record: CKRecord) {
        recordID = record.recordID
        createdDate = record[CloudKeys.CreatedDate.rawValue] as! NSDate
        identifier = record[CloudKeys.Identifier.rawValue] as! String
        location = record[CloudKeys.Location.rawValue] as! CLLocation
        locationTitle = record[CloudKeys.Title.rawValue] as? String
        textContent = record[CloudKeys.Content.rawValue] as? String
        itemName = record[CloudKeys.ItemName.rawValue] as? String
        itemPhoneNumber = record[CloudKeys.ItemNumber.rawValue] as? String
        itemWebLink = record[CloudKeys.ItemLink.rawValue] as? String
        
        if let placemarkData = record[CloudKeys.Place.rawValue] as? NSData {
            place = NSKeyedUnarchiver.unarchiveObjectWithData(placemarkData) as? CLPlacemark
        }
    }
    
    init(localLocation: Location) {
        createdDate = localLocation.date
        identifier = localLocation.identifier
        location = localLocation.location
        locationTitle = localLocation.locationTitle
        textContent = localLocation.textContent
        place = localLocation.placemark
        itemName = localLocation.mapItem?.name
        itemPhoneNumber = localLocation.mapItem?.phoneNumber
        itemWebLink = localLocation.mapItem?.url?.absoluteString
    }
    
    init(dbLocation: DatabaseLocation) {
        if let data = dbLocation.cloudRecordIdentifierData, let recordID = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? CKRecordID {
            self.recordID = recordID
        }

        createdDate = dbLocation.date
        identifier = dbLocation.identifier
        location = dbLocation.location
        locationTitle = dbLocation.locationTitle
        textContent = dbLocation.textContent
        place = dbLocation.placemark
        itemName = dbLocation.itemName
        itemPhoneNumber = dbLocation.itemPhoneNumber
        itemWebLink = dbLocation.itemWebLink
    }
    
}
