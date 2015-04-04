//
//  ViewController.swift
//  Whereabouts
//
//  Created by Ryan Ackermann on 10/20/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

import UIKit
import QuartzCore
import MapKit
import CoreLocation
import AudioToolbox

class MainViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    // Core Location Variales
    let locationManager = CLLocationManager()
    var location: CLLocation!
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    
    // Foundational Variables
    var lastGeocodingError: NSError?
    var timer: NSTimer?
    var lastLocationError: NSError?
    
    // Conditionals
    var performingReversGeocoding: Bool = false
    var updatingLocation: Bool = false
    
    // Sound ID's
    var tapAudioEffect: SystemSoundID = 0
    //var locationAudioEffect: SystemSoundID = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initSounds()
    }
    
    override func viewDidDisappear(animated: Bool) {
        location = nil
        lastLocationError = nil
        placemark = nil
        lastGeocodingError = nil
    }
    
    //MARK: - Init Methods
    
    func initSounds() {
        var tapSoundPath = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Satisfying Click", ofType: "wav")!)
        //var locationSoundPath = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Satisfying Click", ofType: "wav")!)
        
        AudioServicesCreateSystemSoundID(tapSoundPath! as CFURLRef, &tapAudioEffect)
        //AudioServicesCreateSystemSoundID(locationSoundPath! as CFURLRef, &locationAudioEffect)
    }
    
    //MARK: - Button Actions
    
    func saveAction(sender:UIButton!) {
        if let placemark = self.placemark {
            AudioServicesPlaySystemSound(tapAudioEffect)
            showMessageBannerWithText("Location Saved", color: UIColor.emeraldColor())
            if let pageVC = self.parentViewController as RAPageViewController? {
                pageVC.addPage(Recent(placemark: placemark, timeStamp: NSDate()))
            }
        } else {
            showMessageBannerWithText("Placemark Error", color: UIColor.alizarinColor())
        }
    }
    
    func shareAction(sender:UIButton!) {
        if let placemark = self.placemark {
            AudioServicesPlaySystemSound(tapAudioEffect)
            let firstActivityItem = "I'm at \(longLocationDescription(placemark)), where are you?"
            
            let activityViewController : UIActivityViewController = UIActivityViewController(
                activityItems: [firstActivityItem], applicationActivities: nil)
            
            activityViewController.excludedActivityTypes = [
                UIActivityTypePostToWeibo,
                UIActivityTypePrint,
                UIActivityTypeAssignToContact,
                UIActivityTypeSaveToCameraRoll,
                UIActivityTypeAddToReadingList,
                UIActivityTypePostToFlickr,
                UIActivityTypePostToVimeo,
                UIActivityTypePostToTencentWeibo
            ]
            
            self.presentViewController(activityViewController, animated: true, completion: nil)
        } else {
            showMessageBannerWithText("Placemark Error", color: UIColor.alizarinColor())
        }
    }
    
    func relocateAction(sender:UIButton) {
        AudioServicesPlaySystemSound(tapAudioEffect)
    }
    
    // MARK: - UIStatusBar
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prefersStatusBarHidden() -> Bool {
        // TODO: Do something awesome here :)
        return false
    }
    
    // MARK: - Helpers
    
    func showMessageBannerWithText(text: String, color: UIColor) {
        let bannerHeight: CGFloat = 54.0
        var banner = UIView(frame: CGRect(x: 0, y: -bannerHeight - 25, width: self.view.frame.size.width, height: bannerHeight * 2))
        banner.backgroundColor = color
        
        var label = UILabel(frame: CGRect(x: 0, y: 13, width: banner.frame.width, height: (bannerHeight * 2)))
        label.textAlignment = .Center
        label.text = text
        label.font = UIFont(name: "AvenirNext-Medium", size: 37.0)
        label.textColor = UIColor(hex: 0xecf0f1)
        banner.addSubview(label)
        self.view.addSubview(banner)
        let b = banner.bounds
        UIView.animateWithDuration(0.93, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 5.0, options: .CurveEaseOut, animations: { () -> Void in
            banner.center = CGPoint(x: b.origin.x + b.size.width/2, y: bannerHeight/2)
            }) { _ in
                UIView.animateWithDuration(0.93, delay: 0.69, usingSpringWithDamping: 0.7, initialSpringVelocity: 4.0, options: .CurveEaseIn, animations: { () -> Void in
                    banner.center = CGPoint(x: b.origin.x + b.size.width/2, y: -bannerHeight)
                    }) { _ in
                        banner.removeFromSuperview()
                }
        }
    }
    
    func resizeImage(image: UIImage, byFactor: Float) -> UIImage {
        let size = CGSizeApplyAffineTransform(image.size, CGAffineTransformMakeScale(CGFloat(byFactor), CGFloat(byFactor)))
        let hasAlpha = true
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        image.drawInRect(CGRect(origin: CGPointZero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    
    func bottomBorderForView(view: UIView) {
        var border = CALayer()
        var width = CGFloat(2.0)
        
        border.borderColor = UIColor.lightGrayColor().CGColor
        border.frame = CGRect(x: 0, y: view.frame.size.height - width, width:  view.frame.size.width, height: view.frame.size.height)
        
        border.borderWidth = width
        view.layer.addSublayer(border)
        view.layer.masksToBounds = true
    }
    
    func shortLocationDescription(placemark: CLPlacemark) -> String {
        if placemark.areasOfInterest != nil {
            return "\(placemark.areasOfInterest), \(placemark.administrativeArea)"
        } else {
            return "\(placemark.locality), \(placemark.administrativeArea)"
        }
    }
    
    func longLocationDescription(placemark: CLPlacemark) -> String {
        return "\(placemark.subThoroughfare) \(placemark.thoroughfare), \(placemark.locality), \(placemark.administrativeArea), \(placemark.postalCode)"
    }
    
    func sharableStringFrom(placemark: CLPlacemark) -> String {
        return "\(placemark.subThoroughfare) \(placemark.thoroughfare) \(placemark.locality), \(placemark.administrativeArea)"
    }
    
    func getLocation() {
        
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
        
//        updateLabel()
    }
    
    func didTimeOut() {
        println("*** Time Out")
        
        if location == nil {
            stopLocationManager()
            
            lastLocationError = NSError(domain: "WhereaboutsErrorDomain", code: 1, userInfo: nil)
            
//            updateLabel()
        }
    }
    
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Oh No! :(",
        message:
        "This app needs access to your phones location, please enable is in your privacy settings!",
        preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        
        presentViewController(alert, animated: true, completion: nil)
        
        alert.addAction(okAction)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            updatingLocation = true
            
            timer = NSTimer.scheduledTimerWithTimeInterval(35, target: self, selector: Selector("didTimeOut"), userInfo: nil, repeats: false)
            
//            updateLabel()
        }
    }
    
    func stopLocationManager() {
        if updatingLocation {
            if let timer = timer {
                timer.invalidate()
            }
            
            println("Stopping, and saving to shared user defaults")
            let sharedDefaults = NSUserDefaults(suiteName: "group.net.naturaln0va.Whereabouts")
            var sharableLocationString: String = "Location not found :("
            if let placemark = placemark {
                sharableLocationString = sharableStringFrom(placemark)
            } else {
                if let location = location {
                    sharableLocationString = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
                }
            }
            sharedDefaults?.setObject(sharableLocationString, forKey: "location")
            sharedDefaults?.setObject(NSDate(), forKey: "date")
            
            if let location = sharedDefaults?.objectForKey("location") as? String {
                println("Saved \(location) successfully!")
            }
            
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
//            updateLabel()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("didFailWithError \(error)")
        
        if error.code == CLError.LocationUnknown.rawValue {
            return
        }
        
        lastLocationError = error
        
//        updateLabel()
        
        stopLocationManager()
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let newLocaiton = locations.last as CLLocation
        println("didUpdateLocations \(newLocaiton)")
        
        if newLocaiton.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        
        if newLocaiton.horizontalAccuracy < 0 {
            return
        }
        
        var distance = CLLocationDistance(DBL_MAX)
        if let location = location {
            distance = newLocaiton.distanceFromLocation(location)
        }
        
        if location == nil || location!.horizontalAccuracy > newLocaiton.horizontalAccuracy {
            
            lastLocationError = nil
            location = newLocaiton
//            updateLabel()
            
            if newLocaiton.horizontalAccuracy <= locationManager.desiredAccuracy {
                
                println("*** We're Done")
                stopLocationManager()
                
                if distance > 0 {
                    performingReversGeocoding = false
                }
            }
        }
        
        if !performingReversGeocoding {
            println("*** Going to Geocode")
            
            performingReversGeocoding = true
            
//            updateLabel()
            
            geocoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
                
                self.lastGeocodingError = error
                if error == nil && !placemarks.isEmpty {
                    self.placemark = placemarks.last as? CLPlacemark
                } else {
                    self.placemark = nil
                }
                
                self.performingReversGeocoding = false
//                self.updateLabel()
                self.stopLocationManager()
            })
        } else if distance < 1.0 {
            let timeInterval = newLocaiton.timestamp.timeIntervalSinceDate(location!.timestamp)
            
            if timeInterval > 10 {
                println("*** Force Done!")
                stopLocationManager()
//                updateLabel()
            }
        }
    }

}