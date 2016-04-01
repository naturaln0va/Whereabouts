
import UIKit
import MapKit

class Location: NSObject {
    
    let date: NSDate
    let identifier: String
    let location: CLLocation
    
    var color: UIColor?
    var placemark: CLPlacemark?
    var textContent: String?
    
    private var itemName: String?
    private var itemPhoneNumber: String?
    private var itemWebLink: String?
    
    var mapItem: MKMapItem? {
        guard let place = placemark else {
            return nil
        }
        
        let item = MKMapItem(placemark: MKPlacemark(placemark: place))
        item.name = itemName
        item.phoneNumber = itemPhoneNumber
        
        if let urlString = itemWebLink {
            item.url = NSURL(string: urlString)
        }
        
        return item
    }
    
    init(dbLocation: DatabaseLocation) {
        date = dbLocation.date
        identifier = dbLocation.identifier
        color = dbLocation.color
        textContent = dbLocation.textContent
        placemark = dbLocation.placemark
        location = dbLocation.location
        
        itemName = dbLocation.itemName
        itemPhoneNumber = dbLocation.itemPhoneNumber
        itemWebLink = dbLocation.itemWebLink
    }
    
    init(location: CLLocation) {
        date = NSDate()
        identifier = "\(location.hashValue)+\(location.timestamp.timeIntervalSince1970.hashValue)+\(location.coordinate.longitude.hashValue)+\(location.coordinate.latitude.hashValue)"
        self.location = location
        
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
        itemWebLink = String(mapItem.url)
        
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
