
import UIKit
import CoreLocation


let kHorizontalAccuracyPoor:    CLLocationAccuracy = 5000.0
let kHorizontalAccuracyFair:    CLLocationAccuracy = 2000.0
let kHorizontalAccuracyAverage: CLLocationAccuracy = 150.0
let kHorizontalAccuracyGood:    CLLocationAccuracy = 25.0
let kHorizontalAccuracyBest:    CLLocationAccuracy = 5.0

enum LocationAccuracy
{
    case Poor
    case Fair
    case Average
    case Good
    case Best
}

@objc protocol LocationAssistantDelegate
{
    func receivedLocation(location: CLLocation, finished: Bool)
    optional func receivedAddress(placemark: CLPlacemark)
    optional func authorizationDenied()
    optional func failedToGetLocation()
    optional func failedToGetAddress()
}


class LocationAssistant: NSObject, CLLocationManagerDelegate, LocationAccessViewControllerDelegate
{
    
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    var desiredAccuracy: LocationAccuracy = .Good
    var delegate: LocationAssistantDelegate?
    
    private(set) var parentViewController: UIViewController!
    private(set) var location: CLLocation?
    private(set) var placemark: CLPlacemark?
    private(set) var timer: NSTimer?
    
    private var updatingLocation = false
    private var reverseGeocoding = false
    
    
    init(viewController: UIViewController)
    {
        parentViewController = viewController
    }
    
    // MARK: - Public Methods
    func promptForLocationAccess()
    {
        let locationAccessVC = LocationAccessViewController()
        locationAccessVC.delegate = self
        parentViewController.presentViewController(locationAccessVC, animated: true, completion: nil)
    }
    
    func getLocation()
    {
        checkLocationAuthorization()
        
        if !locationAccess() {
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
    
    func getAddressForLocation(locationToGeocode: CLLocation)
    {
        if !reverseGeocoding {
            reverseGeocoding = true
            
            geocoder.reverseGeocodeLocation(locationToGeocode) { placemarks, error in
                if let p = placemarks where !p.isEmpty && error == nil {
                    if let delegate = self.delegate {
                        delegate.receivedAddress?(p.last!)
                    }
                    self.placemark = p.last!
                }
                else {
                    if let delegate = self.delegate {
                        delegate.failedToGetAddress?()
                    }
                    self.placemark = nil
                }
                self.reverseGeocoding = false
            }
        }
    }
    
    func terminate()
    {
        stopLocationManager()
        delegate = nil
    }
    
    // MARK: - Internal Helpers
    private func accuracyForDesiredAccuracy() -> Double
    {
        switch desiredAccuracy {
        case .Poor:
            return kHorizontalAccuracyPoor
        case .Fair:
            return kHorizontalAccuracyFair
        case .Average:
            return kHorizontalAccuracyAverage
        case .Good:
            return kHorizontalAccuracyGood
        case .Best:
            return kHorizontalAccuracyBest
        }
    }
    
    private func checkLocationAuthorization()
    {
        let authStatus = CLLocationManager.authorizationStatus()
        
        switch authStatus {
        case .AuthorizedAlways:
            break
        case .AuthorizedWhenInUse:
            break
        case .Denied:
            if let delegate = delegate {
                delegate.authorizationDenied?()
            }
            promptForLocationAccess()
            break
        case .NotDetermined:
            promptForLocationAccess()
            break
        case .Restricted:
            promptForLocationAccess()
            break
        }
    }
    
    private func locationAccess() -> Bool
    {
        if CLLocationManager.authorizationStatus() == .Denied ||
            CLLocationManager.authorizationStatus() == .Restricted {
                return false
        }
        else {
            return true
        }
    }
    
    private func startLocationManager()
    {
        if CLLocationManager.locationServicesEnabled() {
            manager.delegate = self
            manager.desiredAccuracy = accuracyForDesiredAccuracy()
            manager.startUpdatingLocation()
            updatingLocation = true
            
            timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "didTimeOut", userInfo: nil, repeats: false)
        }
    }
    
    private func stopLocationManager()
    {
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
        }
    }
    
    func didTimeOut()
    {
        stopLocationManager()
        
        if let delegate = delegate {
            delegate.failedToGetLocation?()
        }
    }
    
    // MARK: - LocationAccessViewController Delegate
    func accessGranted()
    {
        if !locationAccess() {
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }
        else {
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func accessDenied()
    {
        if let delegate = delegate {
            delegate.authorizationDenied?()
        }
    }
    
    // MARK: - CoreLocation Delegate
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError)
    {
        print("Failed with error: \(error.localizedDescription)")
        
        if let delegate = delegate {
            delegate.failedToGetLocation?()
        }
        
        if error.code == CLError.LocationUnknown.rawValue {
            return
        }
        
        stopLocationManager()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if let newLocation = locations.last {
            print("Recieved a new location: \(newLocation)")
            
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
                    if timeInterval > 10 {
                        stopLocationManager()
                        finished = true
                    }
                }
                else {
                    finished = false
                }
                
                if let delegate = delegate {
                    delegate.receivedLocation(location!, finished: finished)
                }
            }
        }
    }
    
}
