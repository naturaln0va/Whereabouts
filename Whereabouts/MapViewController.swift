
import UIKit
import MapKit

class MapViewController: UIViewController {
    
    lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.tintColor = StyleController.sharedController.mainTintColor
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        return mapView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Map"
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            navigationItem.rightBarButtonItem = MKUserTrackingBarButtonItem(mapView: mapView)
            navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        }
        
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
        let locations = PersistentController.sharedController.locations()
        
        if locations.count > 0 {
            mapView.addAnnotations(locations)
            mapView.showAnnotations(locations, animated: true)
        }
    }
    
}
