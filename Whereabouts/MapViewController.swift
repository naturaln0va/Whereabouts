
import UIKit
import MapKit

class MapViewController: UIViewController {
    
    lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.tintColor = StyleController.sharedController.mainTintColor
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.delegate = self
        return mapView
    }()
    
    lazy var timeDialView: KCHorizontalDial = {
        let dial = KCHorizontalDial()
        dial.translatesAutoresizingMaskIntoConstraints = false
        dial.delegate = self
        dial.padding = 14.0
        dial.enableRange = true
        dial.markColor = StyleController.sharedController.navBarTintColor.colorWithAlphaComponent(0.75)
        dial.centerMarkColor = StyleController.sharedController.navBarTintColor
        dial.backgroundColor = StyleController.sharedController.mainTintColor
        return dial
    }()
    
    let manager = CLLocationManager()
    
    private var firstMapLoad = true
    private var shouldAddDroppedPin = true
    private var shouldCheckAuthorization = true
    private var droppedAnnotation: DroppedAnnotation?
    private var locations = [Location]()
    private var visits = [Visit]()
    
    private lazy var geocoder = CLGeocoder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Map"
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            navigationItem.rightBarButtonItem = MKUserTrackingBarButtonItem(mapView: mapView)
            navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        }
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.mapWasLongPressed(_:)))
        mapView.addGestureRecognizer(longPressGesture)
        
        if PersistentController.sharedController.locations().count > 0 {
            view.addSubview(timeDialView)
            view.addSubview(mapView)
            let views = ["map": mapView, "time": timeDialView]
            
            view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[time(==60)][map]|", options: [], metrics: nil, views: views))
            view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[time]|", options: [], metrics: nil, views: views))
            view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[map]|", options: [], metrics: nil, views: views))
        }
        else  {
            view.addSubview(mapView)
            let views = ["map": mapView]
            
            view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[map]|", options: [], metrics: nil, views: views))
            view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[map]|", options: [], metrics: nil, views: views))
        }
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(MapViewController.loadLocationsAndDisplay),
            name: PersistentController.PersistentControllerLocationsDidUpdate,
            object: nil
        )
        
        loadLocationsAndDisplay()
        
        manager.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldCheckAuthorization {
            let authStatus = CLLocationManager.authorizationStatus()
            if authStatus == .NotDetermined {
                let vc = LocationAccessViewController()
                vc.delegate = self
                presentViewController(vc, animated: true, completion: nil)
            }
            else if authStatus == .AuthorizedAlways || authStatus == .AuthorizedAlways {
                mapView.showsUserLocation = true
            }
            
            shouldCheckAuthorization = false
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        filterLocationsToDisplayWithNumberOfDaysSince(0)
    }
    
    // MARK: - Actions
    @objc private func mapWasLongPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            shouldAddDroppedPin = false
            
            if let dropped = droppedAnnotation {
                mapView.removeAnnotation(dropped)
                droppedAnnotation = nil
            }
            
            guard let parentMapView = sender.view as? MKMapView else { return }
            
            let coordniate = parentMapView.convertPoint(
                sender.locationInView(parentMapView),
                toCoordinateFromView: parentMapView
            )
            
            let locationOfDroppedPin = CLLocation(latitude: coordniate.latitude, longitude: coordniate.longitude)
            
            geocoder.reverseGeocodeLocation(locationOfDroppedPin) { [weak self] marks, error in
                let locationToAdd = Location(location: locationOfDroppedPin)
                
                if let mark = marks?.first {
                    locationToAdd.placemark = mark
                }
                else {
                    print("Error getting placemark for coordinate of dropped pin.")
                }
                
                let dropped = DroppedAnnotation(location: locationToAdd)
                self?.droppedAnnotation = dropped
                self?.mapView.addAnnotation(dropped)
            }
        }
        else if sender.state == .Ended || sender.state == .Cancelled {
            shouldAddDroppedPin = true
        }
    }
    
    // MARK: - Helpers
    @objc private func loadLocationsAndDisplay() {
        let locations = PersistentController.sharedController.locations()
        let visits = PersistentController.sharedController.visits()
        
        if locations.count > 0 {
            let sortedLocations = locations.sort { locationOne, locationTwo in
                return locationOne.date.compare(locationTwo.date) == .OrderedAscending
            }
            
            var minDaysSince = 0
            var maxDaysSince = 0
            
            if let lastLocation = sortedLocations.last {
                minDaysSince = NSDate().daysSince(lastLocation.date)
            }
            
            if let firstLocation = sortedLocations.first {
                maxDaysSince = NSDate().daysSince(firstLocation.date)
            }
            
            timeDialView.minimumValue = Double(minDaysSince)
            timeDialView.maximumValue = Double(maxDaysSince)
            
            if firstMapLoad {
                timeDialView.value = timeDialView.minimumValue
            }
        }
        
        self.locations = locations
        self.visits = visits
        
        if locations.count > 0 || visits.count > 0 {
            if mapView.annotations.count > 0 { mapView.removeAnnotations(mapView.annotations) }
            mapView.addAnnotations(locations)
            mapView.addAnnotations(visits)
            mapView.showAnnotations(mapView.annotations, animated: true)
        }
        
        firstMapLoad = false
    }
    
    private func filterLocationsToDisplayWithNumberOfDaysSince(daysSince: Int) {
        let locations = PersistentController.sharedController.locations()
        let visits = PersistentController.sharedController.visits()
        
        let filteredLocations = locations.filter { location in
            return NSDate().daysSince(location.date) >= daysSince
        }
        
        let filteredVisits = visits.filter { visit in
            return NSDate().daysSince(visit.createdDate) >= daysSince
        }
        
        self.locations = filteredLocations
        self.visits = filteredVisits
        
        if filteredLocations.count > 0 || filteredVisits.count > 0 {
            if mapView.annotations.count > 0 { mapView.removeAnnotations(mapView.annotations) }
            mapView.addAnnotations(filteredLocations)
            mapView.addAnnotations(filteredVisits)
            mapView.showAnnotations(mapView.annotations, animated: true)
        }
    }
    
}

// MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is MKUserLocation) {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: String(annotation.hash))
            pinView.canShowCallout = true
            
            let rightButton = UIButton(type: .DetailDisclosure)
            
            if annotation is DroppedAnnotation {
                pinView.animatesDrop = true
                pinView.pinTintColor = MKPinAnnotationView.purplePinColor()
                rightButton.setImage(UIImage(named: "add-plus"), forState: .Normal)
            }
            else if annotation is Visit {
                pinView.animatesDrop = false
                pinView.pinTintColor = MKPinAnnotationView.greenPinColor()
                rightButton.setImage(UIImage(named: "add-plus"), forState: .Normal)
            }
            else {
                rightButton.setImage(UIImage(named: "detail-arrow"), forState: .Normal)
            }
            
            rightButton.tag = annotation.hash
            rightButton.tintColor = StyleController.sharedController.mainTintColor
            pinView.rightCalloutAccessoryView = rightButton
            
            return pinView
        }
        else {
            return nil
        }
    }
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        if let indexOfDroppedPin = views.indexOf({ return $0.annotation is DroppedAnnotation }), let annotationToSelect = views[indexOfDroppedPin].annotation {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.5)), dispatch_get_main_queue()) {
                mapView.selectAnnotation(annotationToSelect, animated: true)
            }
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation else { return }

        if let dropped = annotation as? DroppedAnnotation {
            let alertController = UIAlertController(title: "Dropped Pin", message: nil, preferredStyle: .ActionSheet)
            
            alertController.addAction(UIAlertAction(title: "Save Location", style: .Default) { [weak self] action in
                let nvc = StyledNavigationController(rootViewController: EditViewController(location: dropped.location, isCurrentLocation: false))
                
                if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                    nvc.modalPresentationStyle = .FormSheet
                }
                
                self?.presentViewController(nvc, animated: true, completion: nil)
            })
            
            alertController.addAction(UIAlertAction(title: "Search Near Location", style: .Default) { [weak self] action in
                let region = MKCoordinateRegion(center: dropped.coordinate, span: MKCoordinateSpan(latitudeDelta: 1 / 2, longitudeDelta: 1 / 2))
                let nvc = StyledNavigationController(rootViewController: AddViewController(regionToSearch: region))
                
                if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                    nvc.modalPresentationStyle = .FormSheet
                }
                
                self?.presentViewController(nvc, animated: true, completion: nil)
            })
            
            alertController.addAction(UIAlertAction(title: "Remove Pin", style: .Destructive) { [weak self] action in
                mapView.removeAnnotation(dropped)
                self?.droppedAnnotation = nil
            })
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                alertController.modalPresentationStyle = .Popover
                alertController.popoverPresentationController?.sourceView = mapView
                alertController.popoverPresentationController?.sourceRect = view.frame
            }
            
            presentViewController(alertController, animated: true, completion: nil)
        }
        else {
            if let indexOfLocation = locations.indexOf({ return $0.hash == annotation.hash }) {
                let vc = DetailViewController(location: locations[indexOfLocation])
                vc.currentLocation = mapView.userLocation.location
                
                if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                    let nvc = StyledNavigationController(rootViewController: vc)
                    
                    nvc.modalPresentationStyle = .FormSheet
                    
                    presentViewController(nvc, animated: true, completion: nil)
                }
                else {
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
}

// MARK: - LocationAccessViewControllerDelegate
extension MapViewController: LocationAccessViewControllerDelegate {
    
    func locationAccessViewControllerAccessGranted() {
        dismissViewControllerAnimated(true) {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.manager.requestWhenInUseAuthorization()
            }
        }
    }
    
    func locationAccessViewControllerAccessDenied() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}

// MARK: - CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
    
}

// MARK: - KCHorizontalDialDelegate
extension MapViewController: KCHorizontalDialDelegate {
    
    func horizontalDialDidEndScroll(horizontalDial: KCHorizontalDial) {
        filterLocationsToDisplayWithNumberOfDaysSince(Int(horizontalDial.value))
    }
    
}
