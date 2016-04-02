
import UIKit
import CoreLocation


let kHorizontalAccuracyPoor:    CLLocationAccuracy = 5000.0
let kHorizontalAccuracyFair:    CLLocationAccuracy = 2000.0
let kHorizontalAccuracyAverage: CLLocationAccuracy = 150.0
let kHorizontalAccuracyGood:    CLLocationAccuracy = 25.0
let kHorizontalAccuracyBest:    CLLocationAccuracy = 5.0

let kLocationTimeoutShort:      Int = 10
let kLocationTimeoutNormal:     Int = 15
let kLocationTimeoutLong:       Int = 25
let kLocationTimeoutVeryLong:   Int = 45

@objc protocol LocationAssistantDelegate {
    func locationAssistantReceivedLocation(location: CLLocation, finished: Bool)
    optional func locationAssistantReceivedAddress(placemark: CLPlacemark)
    optional func locationAssistantAuthorizationDenied()
    optional func locationAssistantAuthorizationNeeded()
    optional func locationAssistantFailedToGetLocation()
    optional func locationAssistantFailedToGetAddress()
}

class LocationAssistant: NSObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    var delegate: LocationAssistantDelegate?
    
    private(set) var parentViewController: UIViewController?
    private(set) var location: CLLocation?
    private(set) var placemark: CLPlacemark?
    private var timer: NSTimer?
    
    private var wasLocating = false
    private var updatingLocation = false
    private var monitoringLocationUpdates = false
    private var reverseGeocoding = false
    
    override init() {
        super.init()
    }
    
    init(viewController: UIViewController?) {
        parentViewController = viewController
    }
    
    // MARK: - Public Methods
    func getLocation() {
        wasLocating = true
        
        checkLocationAuthorization()
        
        guard locationAccess() else {
            return
        }
        
        if updatingLocation {
            stopLocationManager()
        }
        else {
            location = nil
            placemark = nil
            startLocationManager()
        }
    }
    
    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }
    
    func requestAlways() {
        manager.requestAlwaysAuthorization()
    }
    
    func placemarkFromString(stringToGeocode geocodeString: String, completion: (CLPlacemark?, NSError?) -> Void) {
        #if MAIN_APP
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        #endif
        geocoder.geocodeAddressString(geocodeString) { marks, error in
            #if MAIN_APP
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            #endif
            if let firstMark = marks?.first where error == nil {
                completion(firstMark, nil)
            }
            else {
                completion(nil, error)
            }
        }
    }
    
    func getAddressForLocation(locationToGeocode: CLLocation) {
        if !reverseGeocoding {
            reverseGeocoding = true
            
            #if MAIN_APP
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            #endif
            geocoder.reverseGeocodeLocation(locationToGeocode) { placemarks, error in
                #if MAIN_APP
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                #endif
                if let p = placemarks where !p.isEmpty && error == nil {
                    if let delegate = self.delegate {
                        delegate.locationAssistantReceivedAddress?(p.last!)
                    }
                    self.placemark = p.last!
                }
                else {
                    if let delegate = self.delegate {
                        delegate.locationAssistantFailedToGetAddress?()
                    }
                    self.placemark = nil
                }
                self.reverseGeocoding = false
            }
        }
    }
    
    func startVisitsMonitoring() {
        if monitoringLocationUpdates {
            return
        }
        
        if CLLocationManager.authorizationStatus() == .AuthorizedAlways {
            monitoringLocationUpdates = true
            
            manager.delegate = self
            manager.desiredAccuracy = kHorizontalAccuracyAverage
            manager.startMonitoringVisits()
        }
        else {
            if let delegate = delegate {
                delegate.locationAssistantAuthorizationNeeded?()
            }
        }
    }
    
    func terminate() {
        delegate = nil
        stopLocationManager()
        if monitoringLocationUpdates { manager.stopMonitoringVisits() }
    }
    
    // MARK: - Internal Helpers
    private func checkLocationAuthorization() {
        let authStatus = CLLocationManager.authorizationStatus()
        
        switch authStatus {
        case .AuthorizedAlways:
            break
        case .AuthorizedWhenInUse:
            break
        case .Denied:
            if let delegate = delegate {
                delegate.locationAssistantAuthorizationDenied?()
            }
            break
        case .NotDetermined:
            if let delegate = delegate {
                delegate.locationAssistantAuthorizationNeeded?()
            }
            break
        case .Restricted:
            if let delegate = delegate {
                delegate.locationAssistantAuthorizationNeeded?()
            }
            break
        }
    }
    
    private func locationAccess() -> Bool {
        if (CLLocationManager.authorizationStatus() == .Denied ||
            CLLocationManager.authorizationStatus() == .Restricted)
            && !CLLocationManager.locationServicesEnabled() {
                return false
        }
        else {
            return true
        }
    }
    
    private func startLocationManager() {
        wasLocating = false
        
        if CLLocationManager.locationServicesEnabled() {
            manager.delegate = self
            manager.desiredAccuracy = SettingsController.sharedController.distanceAccuracy
            manager.startUpdatingLocation()
            updatingLocation = true
            
            let interval = NSTimeInterval(SettingsController.sharedController.locationTimeout)
            timer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(LocationAssistant.didTimeOut), userInfo: nil, repeats: false)
        }
    }
    
    private func stopLocationManager() {
        if updatingLocation {
            if let timer = timer {
                timer.invalidate()
            }
            
            if geocoder.geocoding {
                geocoder.cancelGeocode()
            }
            
            manager.stopUpdatingLocation()
            manager.delegate = nil
            updatingLocation = false
            wasLocating = false
            
            if let delegate = delegate where location != nil {
                delegate.locationAssistantReceivedLocation(location!, finished: true)
            }
        }
    }
    
    internal func didTimeOut() {
        stopLocationManager()
        
        if let delegate = delegate {
            delegate.locationAssistantFailedToGetLocation?()
        }
    }
    
    // MARK: - CoreLocation Delegate
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Failed with error: \(error.localizedDescription)")
        
        if let delegate = delegate {
            delegate.locationAssistantFailedToGetLocation?()
        }
        
        if error.code == CLError.LocationUnknown.rawValue {
            return
        }
        
        stopLocationManager()
    }
    
    func locationManager(manager: CLLocationManager, didVisit visit: CLVisit) {
        #if MAIN_APP
            var visitNotificationString = ""
            if visit.departureDate.isEqualToDate(NSDate.distantFuture()) {
                visitNotificationString += "Arrived at: "
            } else {
                visitNotificationString += "Departed from: "
            }
            
            let locationOfVisit = CLLocation(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude)
            var addressOfVisit: CLPlacemark?
            
            if let visits = try? Visit.objectsInContext(PersistentController.sharedController.visitMOC) {
                for visit in visits {
                    if visit.location.distanceFromLocation(locationOfVisit) < 500.0 {
                        PersistentController.sharedController.visitWasVisited(visit)
                        
                        let notification = UILocalNotification()
                        notification.alertAction = nil
                        notification.alertBody = "You have now Visited \(visit.address == nil ? stringFromCoordinate(visit.coordinate) : stringFromAddress(visit.address!, withNewLine: false)) \(visit.totalVisits)"
                        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
                        return
                    }
                }
            }
            
            geocoder.reverseGeocodeLocation(locationOfVisit) { placemarks, error in
                if let visitedAddress = placemarks?.last where error == nil {
                    
                    addressOfVisit = visitedAddress
                    visitNotificationString += stringFromAddress(visitedAddress, withNewLine: true)
                }
                else {
                    visitNotificationString += stringFromCoordinate(visit.coordinate)
                }
                
                let notification = UILocalNotification()
                notification.alertAction = nil
                notification.alertBody = visitNotificationString
                UIApplication.sharedApplication().presentLocalNotificationNow(notification)
            }
            
            PersistentController.sharedController.saveVisit(
                visit.arrivalDate,
                departureDate: visit.departureDate,
                horizontalAccuracy: visit.horizontalAccuracy,
                coordinate: visit.coordinate,
                address: addressOfVisit
            )
        #endif
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = locations.last {
            if newLocation.timestamp.timeIntervalSinceNow < -5 ||
                newLocation.horizontalAccuracy < 0 {
                return
            }
            
            var distance = CLLocationDistance(DBL_MAX)
            if let location = location {
                distance = newLocation.distanceFromLocation(location)
            }
            
            if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
                location = newLocation
                
                var finished = false
                if newLocation.horizontalAccuracy <= manager.desiredAccuracy {
                    stopLocationManager()
                    finished = true
                } else if distance < 1.0 {
                    let timeInterval = newLocation.timestamp.timeIntervalSinceDate(location!.timestamp)
                    if timeInterval > 8 {
                        stopLocationManager()
                        finished = true
                    }
                }
                else {
                    finished = false
                }
                
                if let delegate = delegate {
                    delegate.locationAssistantReceivedLocation(location!, finished: finished)
                }
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
            
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            if wasLocating { getLocation() }
            
        default:
            break
            
        }
    }
    
}
