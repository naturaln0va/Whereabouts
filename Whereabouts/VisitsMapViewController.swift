
import UIKit
import MapKit

class VisitsMapViewController: UIViewController {
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.delegate = self
        if #available(iOS 9.0, *) {
            mapView.showsCompass = true
            mapView.showsScale = true
        }
        return mapView
    }()
    
    private var visits: [Visit]? {
        didSet {
            if let visits = visits {
                mapView.removeAnnotations(mapView.annotations)
                mapView.addAnnotations(visits)
                mapView.showAnnotations(visits, animated: false)
            }
        }
    }
    private var shouldContinueUpdatingUserLocation = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Recent Visits"
        view.backgroundColor = ColorController.backgroundColor
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .Plain,
            target: self,
            action: "doneButtonPressed"
        )
        
        navigationItem.leftBarButtonItem = MKUserTrackingBarButtonItem(mapView: mapView)
        navigationItem.leftBarButtonItem?.enabled = false
        
        view.translatesAutoresizingMaskIntoConstraints = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mapView)
        let views = ["map": mapView]
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[map]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[map]|", options: [], metrics: nil, views: views))
        
        do {
            visits = try Visit.objectsInContext(PersistentController.sharedController.visitMOC)
        }
        catch {
            print("Error fetching visits.")
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    // MARK: - Actions
    func doneButtonPressed() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}

extension VisitsMapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        guard shouldContinueUpdatingUserLocation else { return }
        
        if visits != nil {
            mapView.showAnnotations(mapView.annotations, animated: true)
            navigationItem.leftBarButtonItem?.enabled = true
            shouldContinueUpdatingUserLocation = false
        }
    }
    
}
