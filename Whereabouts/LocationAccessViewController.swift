
import UIKit
import MapKit

@objc protocol LocationAccessViewControllerDelegate {
    optional func locationAccessViewControllerAccessGranted()
    optional func locationAccessViewControllerAccessDenied()
}

class LocationAccessViewController: UIViewController {
    
    @IBOutlet var mapView: MKMapView!
    var delegate: LocationAccessViewControllerDelegate?
    
    private lazy var camera: MKMapCamera = {
        let camera = MKMapCamera()
        camera.heading = 0
        camera.pitch = 45
        camera.altitude = 700
        return camera
    }()
    
    private let headingStep = 10.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.mapType = .SatelliteFlyover
        mapView.showsCompass = false
        mapView.showsScale = false
        
        let centerCoordinate = CLLocationCoordinate2D(latitude: 37.826040, longitude: -122.479448)
        camera.centerCoordinate = centerCoordinate
        
        mapView.setRegion(MKCoordinateRegionMakeWithDistance(centerCoordinate, 1000, 1000), animated: false)

        view.backgroundColor = UIColor(red: 0.239,  green: 0.239,  blue: 0.239, alpha: 1.0)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        mapView.setCamera(camera, animated: true)
        mapView.delegate = self
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    @IBAction func accessButtonPressed(sender: AnyObject) {
        if let delegate = delegate {
            delegate.locationAccessViewControllerAccessGranted?()
        }
    }
    
    @IBAction func noThanksButtonPressed(sender: AnyObject) {
        if let delegate = delegate {
            delegate.locationAccessViewControllerAccessDenied?()
        }
    }
    
}

extension LocationAccessViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let cameraCopy = self.mapView.camera.copy() as! MKMapCamera
        cameraCopy.heading = fmod(cameraCopy.heading + headingStep, 360)
        
        UIView.animateWithDuration(1.0, delay: 0, options: .CurveLinear, animations: {
            self.mapView.camera = cameraCopy
        }, completion: nil)
    }
    
}
