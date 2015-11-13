//
//  Created by Ryan Ackermann on 5/29/15.
//  Copyright (c) 2015 Ryan Ackermann. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation


class MapViewController: RHAViewController, CLLocationManagerDelegate, MKMapViewDelegate
{
    // Singleton Instance
    static let sharedController = MapViewController()
    
    // Core Location Variables
    let locationManager = CLLocationManager()
    var location: CLLocation!
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var currentUserAnnotation: RHACurrentLocationAnnotation?
    
    // Foundational Variables
    var lastGeocodingError: NSError?
    var timer: NSTimer?
    var lastLocationError: NSError?
    
    // Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    // Conditionals
    var performingReversGeocoding: Bool = false
    var updatingLocation: Bool = false
    
    //MARK: - ViewController Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //tabBarItem = UITabBarItem(image: UIImage(named: "map-menu-icon"))
        title = "Locating..."
        
        let refreshBarButton = UIBarButtonItem(image: UIImage(named: "refresh-bar-button.png"), style: .Plain, target: self, action: "refreshButtonWasPressed")
        let addBarButton = UIBarButtonItem(image: UIImage(named: "add-bar-button.png")!, style: .Plain, target: self, action: "addButtonWasPressed")
        
        navigationItem.rightBarButtonItem = refreshBarButton
        navigationItem.leftBarButtonItem = addBarButton
        
        mapView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "shareAction"))
        mapView.delegate = self
        mapView.alpha = 0.0
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if let location = location {
            if location.timestamp.timeIntervalSinceNow < -30.0 {
                print("Trying to get updated location, time interval was: \(location.timestamp.timeIntervalSinceNow)")
            }
        }
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        getLocation()
    }
    
    override func viewDidDisappear(animated: Bool)
    {
        lastLocationError = nil
        placemark = nil
        lastGeocodingError = nil
    }
    
    //MARK: - Actions
    func refreshButtonWasPressed()
    {
        print("Refreshing...")
        if CLLocationManager.locationServicesEnabled() {
            
            if updatingLocation {
                location = nil
                lastLocationError = nil
                placemark = nil
                lastGeocodingError = nil
            }
            
            getLocation()
        }
    }
    
    func addButtonWasPressed()
    {
        print("Adding...")
        //LocationsController.sharedController.saveData(Recent(placemark: self.placemark!, timeStamp: NSDate()))
    }
    
    func shareAction()
    {
        if let placemark = self.placemark {
            let firstActivityItem = "I'm at \(longLocationDescription(placemark)). Where are you?"
            
            let shareViewController : UIActivityViewController = UIActivityViewController(
                activityItems: [firstActivityItem], applicationActivities: nil)
            
            shareViewController.excludedActivityTypes = [
                UIActivityTypePostToWeibo,
                UIActivityTypePrint,
                UIActivityTypeAssignToContact,
                UIActivityTypeSaveToCameraRoll,
                UIActivityTypeAddToReadingList,
                UIActivityTypePostToFlickr,
                UIActivityTypePostToVimeo,
                UIActivityTypePostToTencentWeibo
            ]
            
            self.presentViewController(shareViewController, animated: true, completion: nil)
        } else {
            //showMessageBannerWithText("Placemark Error", color: UIColor.alizarinColor())
        }
    }
    
    //MARK: - MapKit Delegate
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        if annotation is RHACurrentLocationAnnotation {
            let identifier = "UserLocation"
            var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView!.enabled = true
                annotationView!.canShowCallout = true
                annotationView!.image = UIImage(named: "user-location-indicator.png")
            } else {
                annotationView!.annotation = annotation
            }
            
            return annotationView
        }
        
        return nil
    }
    
    //MARK: - Location Delegate & Helpers
    func getLocation()
    {
        let authStatus: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        
        // TODO: Add fancy animation for a
        //       detail explination why this app needs location data access
        
        if authStatus == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if authStatus == .Denied || authStatus == .Restricted {
            showLocationServicesDeniedAlert()
            return
        }
        
        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }
    }
    
    func didTimeOut()
    {
        print("*** Time Out")
        
        if location == nil {
            stopLocationManager()
            
            lastLocationError = NSError(domain: "WhereaboutsErrorDomain", code: 1, userInfo: nil)
        }
    }
    
    func showLocationServicesDeniedAlert()
    {
        let alert = UIAlertController(title: "Oh No! :(",
            message:
            "This app needs access to your phones location, please enable is in your privacy settings!",
            preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        
        presentViewController(alert, animated: true, completion: nil)
        
        alert.addAction(okAction)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func startLocationManager()
    {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            updatingLocation = true
            
            timer = NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: Selector("didTimeOut"), userInfo: nil, repeats: false)
            
            title = "Locating..."
        }
    }
    
    func stopLocationManager()
    {
        if updatingLocation {
            if let timer = timer {
                timer.invalidate()
            }
            
            print("Stopping, and saving to shared user defaults")
            let sharedDefaults = NSUserDefaults(suiteName: "group.net.naturaln0va.Whereabouts")
            var sharableLocationString: String = ""
            if let placemark = placemark {
                sharableLocationString = sharableStringFrom(placemark)
                sharedDefaults?.setObject(sharableLocationString, forKey: "location")
                sharedDefaults?.setObject(NSDate(), forKey: "date")
                
                if let location = sharedDefaults?.objectForKey("location") as? String {
                    print("Saved \(location) successfully!")
                }
                title = shortLocationDescription(placemark)
                navigationItem.prompt = detailLocationDescription(placemark)
                
                UIView.animateWithDuration(0.3, animations: {
                    self.mapView.alpha = 1.0
                })
                
                let shouldAnimate = mapView.region.span.latitudeDelta < 55
                let region = MKCoordinateRegionMakeWithDistance(placemark.location!.coordinate, 1000, 1000)
                mapView.setRegion(mapView.regionThatFits(region), animated: shouldAnimate)
                
                self.currentUserAnnotation = RHACurrentLocationAnnotation(latitude: placemark.location!.coordinate.latitude, longitude: placemark.location!.coordinate.longitude)
                
                if let annotation = currentUserAnnotation {
                    mapView.addAnnotation(annotation)
                }
            } else {
                if let location = location {
                    sharableLocationString = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
                    sharedDefaults?.setObject(sharableLocationString, forKey: "location")
                    sharedDefaults?.setObject(NSDate(), forKey: "date")
                    
                    if let location = sharedDefaults?.objectForKey("location") as? String {
                        print("Saved \(location) successfully!")
                    }
                    title = "Cannot Find Address"
                    navigationItem.prompt = sharableLocationString
                    
                    UIView.animateWithDuration(0.3, animations: {
                        self.mapView.alpha = 1.0
                    })
                } else {
                    title = "Location Not Found"
                }
            }
            
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError)
    {
        print("didFailWithError \(error)")
        
        if error.code == CLError.LocationUnknown.rawValue {
            return
        }
        
        lastLocationError = error
        stopLocationManager()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if let newLocaiton = locations.last {
            
            if newLocaiton.timestamp.timeIntervalSinceNow < -5
                || newLocaiton.horizontalAccuracy < 0 {
                    return
            }
            
            var distance = CLLocationDistance(DBL_MAX)
            if let location = location {
                distance = newLocaiton.distanceFromLocation(location)
            }
            
            if location == nil || location.horizontalAccuracy > newLocaiton.horizontalAccuracy {
                lastLocationError = nil
                location = newLocaiton
                
                if newLocaiton.horizontalAccuracy <= locationManager.desiredAccuracy {
                    stopLocationManager()
                    
                    if distance > 0 {
                        performingReversGeocoding = false
                    }
                }
            }
            
            if !performingReversGeocoding {
                performingReversGeocoding = true
                
                geocoder.reverseGeocodeLocation(newLocaiton, completionHandler: {
                    placemarks, error in
                    
                    if let marks = placemarks {
                        self.placemark = marks.last
                        self.performingReversGeocoding = false
                        self.stopLocationManager()
                    }
                    else {
                        self.lastGeocodingError = error
                    }
                })
            }
            else if distance < 1.0 {
                let timeInterval = newLocaiton.timestamp.timeIntervalSinceDate(location.timestamp)
                
                if timeInterval > 5 {
                    stopLocationManager()
                }
            }
        }
    }
}