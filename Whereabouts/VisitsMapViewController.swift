
import UIKit
import MapKit


class VisitsMapViewController: UIViewController
{
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.bounds = self.view.bounds
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
            guard let _ = visits else { return }
            refreshMapWithVisits(visits!)
        }
    }
    private var shouldContinueUpdatingUserLocation = true
    
    private lazy var centerLocationItem: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(named: "location-arrow"), style: .Plain, target: self, action: "locateButtonPressed")
    }()
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        title = "Recent Visits"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Done,
            target: self,
            action: "doneButtonPressed"
        )
        
        navigationItem.leftBarButtonItem = centerLocationItem
        navigationItem.leftBarButtonItem?.enabled = false
        
        do {
            visits = try Visit.objectsInContext(PersistentController.sharedController.visitMOC)
        }
        catch {
            print("Error fetching visits.")
        }
    }
    
    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()
        mapView.bounds = view.bounds
    }
    
    // MARK: - Actions
    func doneButtonPressed()
    {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func locateButtonPressed()
    {
        if let visits = visits {
            refreshMapWithVisits(visits)
        }
        else {
            guard let userLocation = mapView.userLocation.location else { return }
            
            let userRegion = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 1 / 55, longitudeDelta: 1 / 55)
            )
            mapView.setRegion(mapView.regionThatFits(userRegion), animated: false)
        }
    }
    
    // MARK: - Private
    private func refreshMapWithVisits(visits: [Visit])
    {
        guard let userLocation = mapView.userLocation.location else {
            print("No user location when attempting to refresh the mapView.")
            return
        }
        
        shouldContinueUpdatingUserLocation = false
        
        var locations = visits.map { return $0.locationCoordinate }
        locations.append(userLocation)
        
        let sortedLocations = locations.count > 1 ? locations.sort {
            $0.distanceFromLocation(userLocation) > $1.distanceFromLocation(userLocation)
        } : locations
        
        var center = CLLocationCoordinate2D()
        var span = MKCoordinateSpan()
        if sortedLocations.count == 1 { // no visits, define a region around the user's location
            center = CLLocationCoordinate2D(
                latitude: userLocation.coordinate.latitude,
                longitude: userLocation.coordinate.longitude
            )
            span = MKCoordinateSpan(
                latitudeDelta: 1 / 55,
                longitudeDelta: 1 / 55
            )
        }
        else {
            var topLeftCoord = CLLocationCoordinate2D(
                latitude: -90,
                longitude: 180
            )
            var bottomRightCoord = CLLocationCoordinate2D(
                latitude: 90,
                longitude: -180
            )
            
            for location in sortedLocations {
                topLeftCoord.latitude = max(
                    topLeftCoord.latitude,
                    location.coordinate.latitude
                )
                topLeftCoord.longitude = min(
                    topLeftCoord.longitude,
                    location.coordinate.longitude
                )
                bottomRightCoord.latitude = min(
                    bottomRightCoord.latitude,
                    location.coordinate.latitude
                )
                bottomRightCoord.longitude = max(
                    bottomRightCoord.longitude,
                    location.coordinate.longitude
                )
            }
            
            center = CLLocationCoordinate2D(
                latitude: topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) / 2,
                longitude: topLeftCoord.longitude - (topLeftCoord.longitude - bottomRightCoord.longitude) / 2
            )
            span = MKCoordinateSpan(
                latitudeDelta: abs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.5,
                longitudeDelta: abs(topLeftCoord.longitude - bottomRightCoord.longitude) * 1.5
            )
        }
        
        let fittedRegion = mapView.regionThatFits(MKCoordinateRegionMake(center, span))
        navigationItem.leftBarButtonItem?.enabled = true
        
        mapView.setRegion(fittedRegion, animated: true)
        mapView.addAnnotations(visits)
    }

}


extension VisitsMapViewController: MKMapViewDelegate
{
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation)
    {
        guard shouldContinueUpdatingUserLocation else { return }
        
        mapView.setRegion(MKCoordinateRegion(center: userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 1 / 55, longitudeDelta: 1 / 55)), animated: false)
        navigationItem.leftBarButtonItem?.enabled = true
    }
    
}
