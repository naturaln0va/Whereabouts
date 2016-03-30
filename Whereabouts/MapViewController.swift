
import UIKit
import MapKit

class MapViewController: UIViewController {
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        return mapView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Map"
        
        navigationItem.leftBarButtonItem = MKUserTrackingBarButtonItem(mapView: mapView)
        navigationItem.leftBarButtonItem?.enabled = false
        
        view.translatesAutoresizingMaskIntoConstraints = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mapView)
        let views = ["map": mapView]
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[map]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[map]|", options: [], metrics: nil, views: views))
        
        loadLocationsAndDisplay()
    }
    
    // MARK: Helpers
    private func loadLocationsAndDisplay() {
        if let locations = try? Location.objectsInContext(PersistentController.sharedController.locationMOC) {
            mapView.addAnnotations(locations)
            mapView.showAnnotations(locations, animated: true)
        }
    }
    
}
