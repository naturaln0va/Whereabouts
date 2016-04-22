
import UIKit
import MapKit
import CoreSpotlight

class Location: NSObject {
    
    let date: NSDate
    let identifier: String
    
    var location: CLLocation
    
    var placemark: CLPlacemark?
    var locationTitle: String?
    var textContent: String?
    
    private var itemName: String?
    private var itemPhoneNumber: String?
    private var itemWebLink: String?
    
    private lazy var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.timeStyle = .NoStyle
        formatter.dateStyle = .ShortStyle
        return formatter
    }()
    
    var mapItem: MKMapItem? {
        guard let place = placemark, let name = itemName else {
            return nil
        }
        
        let item = MKMapItem(placemark: MKPlacemark(placemark: place))
        item.name = name
        
        if let phone = itemPhoneNumber {
            item.phoneNumber = phone
        }
        
        if let urlString = itemWebLink {
            item.url = NSURL(string: urlString)
        }
        
        return item
    }
    
    // MARK: - Initializers
    
    init(dbLocation: DatabaseLocation) {
        date = dbLocation.date
        identifier = dbLocation.identifier
        locationTitle = dbLocation.locationTitle
        textContent = dbLocation.textContent
        placemark = dbLocation.placemark
        location = dbLocation.location
        
        itemName = dbLocation.itemName
        itemPhoneNumber = dbLocation.itemPhoneNumber
        itemWebLink = dbLocation.itemWebLink
        
        super.init()
    }
    
    init(location: CLLocation) {
        date = NSDate()
        identifier = "\(location.hashValue)+\(location.timestamp.timeIntervalSince1970.hashValue)+\(location.coordinate.longitude.hashValue)+\(location.coordinate.latitude.hashValue)"
        self.location = location
        
        super.init()
    }
    
    init(cloudLocation: CloudLocation) {
        date = cloudLocation.createdDate
        identifier = cloudLocation.identifier
        locationTitle = cloudLocation.locationTitle
        textContent = cloudLocation.textContent
        location = cloudLocation.location
        placemark = cloudLocation.place
        
        itemName = cloudLocation.itemName
        itemPhoneNumber = cloudLocation.itemPhoneNumber
        itemWebLink = cloudLocation.itemWebLink
        
        super.init()
    }
    
    init?(mapItem: MKMapItem) {
        guard let itemLocation = mapItem.placemark.location else {
            return nil
        }
        
        date = NSDate()
        location = itemLocation
        placemark = mapItem.placemark
        identifier = "\(location.hashValue)+\(location.timestamp.timeIntervalSince1970.hashValue)+\(location.coordinate.longitude.hashValue)+\(location.coordinate.latitude.hashValue)"
        itemName = mapItem.name
        itemPhoneNumber = mapItem.phoneNumber
        
        if let urlString = mapItem.url?.absoluteString {
            itemWebLink = urlString
        }
        
        super.init()
    }
    
    // MARK: - Helpers
    
    var shareableString: String {
        var shareString = ""
        
        if let content = textContent {
            shareString += content + "\n"
        }
        
        if let place = placemark {
            shareString += stringFromAddress(place, withNewLine: false)
        }
        else {
            shareString += location.coordinate.formattedString()
        }
        
        shareString += "\nvia Whereabouts: http://appstore.com/whereaboutslocationutility"
        
        return shareString
    }
    
}

// MARK: - MKAnnotation
extension Location: MKAnnotation {
    
    var title: String? {
        if let locationTitle = locationTitle {
            return locationTitle
        }
        else if let item = mapItem {
            return item.name
        }
        else if let place = placemark {
            return place.fullFormatedString()
        }
        else {
            return location.coordinate.formattedString()
        }
    }
    
    var subtitle: String? {
        if locationTitle != nil || mapItem != nil {
            if let item = mapItem {
                return item.placemark.fullFormatedString()
            }
            else if let place = placemark {
                return place.fullFormatedString()
            }
        }
        
        return nil
    }
    
    var coordinate: CLLocationCoordinate2D {
        return location.coordinate
    }
    
}

// MARK: - CoreSpotlight
extension Location {
    
    var searchableAttributes: CSSearchableItemAttributeSet {
        let attr = CSSearchableItemAttributeSet(itemContentType: "\(NSBundle.mainBundle().bundleIdentifier).location")
        attr.title = title
        attr.contentCreationDate = date
        attr.city = placemark?.locality
        attr.country = placemark?.country
        attr.stateOrProvince = placemark?.administrativeArea
        attr.namedLocation = mapItem?.name
        attr.contentDescription = textContent ?? mapItem?.phoneNumber ?? ("Created on: " + dateFormatter.stringFromDate(date))
        attr.altitude = NSNumber(double: location.altitude)
        attr.latitude = NSNumber(double: coordinate.latitude)
        attr.longitude = NSNumber(double: coordinate.longitude)
        return attr
    }
    
}
