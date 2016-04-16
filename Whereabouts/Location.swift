
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
    
    var shareableString: String {
        var shareString = ""
        
        if let content = textContent {
            shareString += content + "\n"
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

// MARK: - MKAnnotation
extension Location: MKAnnotation {
    
    var title: String? {
        if let item = mapItem {
            return item.name
        }
        else if let place = placemark {
            return place.fullFormatedString()
        }
        else {
            return stringFromCoordinate(location.coordinate)
        }
    }
    
    var subtitle: String? {
        if let item = mapItem {
            return item.placemark.fullFormatedString()
        }
        else if let _ = placemark {
            return stringFromCoordinate(location.coordinate)
        }
        else {
            return nil
        }
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
        attr.contentDescription = textContent ?? mapItem?.phoneNumber
        attr.altitude = NSNumber(double: location.altitude)
        attr.latitude = NSNumber(double: coordinate.latitude)
        attr.longitude = NSNumber(double: coordinate.longitude)
        return attr
    }
    
}
