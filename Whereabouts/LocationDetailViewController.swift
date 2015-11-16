
import UIKit
import MapKit


class LocationDetailViewController: UIViewController
{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var locationInformationView: UIView!
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var coordinateLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var toolBar: UIToolbar!
    
    private let numberFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.minimumFractionDigits = 3
        return formatter
    }()

    var locationToDisplay: Location!
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "editButtonPressed")
        
        locationInformationView.layer.cornerRadius = 4.0
        locationInformationView.layer.shadowColor = UIColor.blackColor().CGColor
        locationInformationView.layer.shadowOpacity = 0.125
        locationInformationView.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        locationInformationView.layer.shadowRadius = 2.5
        
        mapView.delegate = self
        
        colorView.layer.cornerRadius = 10.0
        toolBar.tintColor = ColorController.navBarBackgroundColor
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        refreshView()
    }
    
    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()
        mapWidthConstraint.constant = CGRectGetWidth(view.bounds)
    }
    
    // MARK: - Actions
    func editButtonPressed()
    {
        let newlocationVC = NewLocationViewController()
        newlocationVC.locationToEdit = locationToDisplay
        newlocationVC.delegate = self
        presentViewController(StyledNavigationController(rootViewController: newlocationVC), animated: true, completion: nil)
    }
    
    @IBAction func actionButtonPressed(sender: AnyObject)
    {
        let firstActivityItem = "I'm at \(locationToDisplay.shareableString()), where are you?"
        
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [firstActivityItem], applicationActivities: nil)
        
        activityViewController.excludedActivityTypes = [
            UIActivityTypePrint,
            UIActivityTypeAssignToContact,
            UIActivityTypeSaveToCameraRoll,
            UIActivityTypeAddToReadingList,
            UIActivityTypePostToFlickr,
            UIActivityTypePostToVimeo
        ]
        
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    private func refreshView()
    {
        title = locationToDisplay.title

        mapView.addAnnotation(locationToDisplay)
        
        if #available(iOS 9.0, *) {
            mapView.showsCompass = true
            mapView.showsScale = true
        }
        
        if let address = locationToDisplay.placemark {
            addressLabel.attributedText = stringFromAddress(address, withNewLine: true).basicAttributedString()
            coordinateLabel.text = stringFromCoordinate(locationToDisplay.location.coordinate)
        }
        else {
            addressLabel.text = stringFromCoordinate(locationToDisplay.location.coordinate)
            coordinateLabel.text = "No Address Found"
        }
        
        altitudeLabel.text = locationToDisplay.location.altitude == 0.0 ? "At sea level" :  "\(numberFormatter.stringFromNumber(NSNumber(double: locationToDisplay.location.altitude))!)m " + (locationToDisplay.location.altitude > 0 ? "above sea level" : "below sea level")
        dateLabel.text = relativeStringForDate(locationToDisplay.location.timestamp)
        colorView.backgroundColor = locationToDisplay.color ?? UIColor.clearColor()
    }

}


extension LocationDetailViewController: MKMapViewDelegate
{
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation)
    {
        let center = CLLocationCoordinate2D(
            latitude: userLocation.coordinate.latitude - (userLocation.coordinate.latitude - locationToDisplay.location.coordinate.latitude) / 2,
            longitude: userLocation.coordinate.longitude - (userLocation.coordinate.longitude - locationToDisplay.location.coordinate.longitude) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: abs(userLocation.coordinate.latitude - locationToDisplay.location.coordinate.latitude) * 250,
            longitudeDelta: abs(userLocation.coordinate.longitude - locationToDisplay.location.coordinate.longitude) * 250
        )
        let region = MKCoordinateRegionMake(center, span)
        mapView.setRegion(mapView.regionThatFits(region), animated: false)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        guard annotation is Location else {
            return nil
        }
        
        let reuseIdentifier = "Location"
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier) as! MKPinAnnotationView!
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView.enabled = true
            annotationView.canShowCallout = true
            annotationView.animatesDrop = false
            
            if #available(iOS 9.0, *) {
                annotationView.pinTintColor = locationToDisplay.color
            } else {
                annotationView.pinColor = MKPinAnnotationColor.Red
            }
            
            let rightButton = UIButton(type: .DetailDisclosure)
            rightButton.addTarget(self, action: "annotationButtonPressed", forControlEvents: .TouchUpInside)
            annotationView.rightCalloutAccessoryView = rightButton
        }
        else {
            annotationView.annotation = annotation
        }
        
        return annotationView
    }
    
    func annotationButtonPressed()
    {
        UIApplication.sharedApplication().openURL(NSURL(string: "http://maps.apple.com/?ll=\(locationToDisplay.location.coordinate.latitude),\(locationToDisplay.location.coordinate.longitude)")!)
    }
    
}


extension LocationDetailViewController: NewLocationViewControllerDelegate
{
    
    func newLocationViewControllerDidEditLocation(editedLocation: Location)
    {
        locationToDisplay = editedLocation
    }
    
}
