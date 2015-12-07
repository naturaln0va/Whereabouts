
import UIKit
import NotificationCenter
import CoreLocation


class TodayViewController: UIViewController, NCWidgetProviding
{
        
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var altitudeLabel: UILabel!
    
    var location: CLLocation? {
        didSet {
            if location != nil {
                updateView()
            }
        }
    }
    var placemark: CLPlacemark? {
        didSet {
            if placemark != nil {
                updateView()
            }
        }
    }
    
    let assistant = LocationAssistant(viewController: nil)
    //let sharedDefaults = NSUserDefaults(suiteName: "group.net.naturaln0va.Whereabouts")
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        assistant.delegate = self
        
        locationLabel.text = "Locating..."
        altitudeLabel.text = "-"
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: "relocate")
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        if location == nil {
            assistant.getLocation()
        }
        else {
            updateView()
        }
    }
    
    func relocate()
    {
        locationLabel.text = "Locating..."
        altitudeLabel.text = "-"

        location = nil
        placemark = nil
        activityIndicator.startAnimating()
        assistant.getLocation()
    }
    
    func updateView()
    {
        guard let location = location else {
            return
        }
        locationLabel.text = stringFromCoordinate(location.coordinate)
        altitudeLabel.text = altitudeString(location.altitude)
        
        guard let address = placemark else {
            return
        }
        locationLabel.text = stringFromAddress(address, withNewLine: true)
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets
    {
        return UIEdgeInsets(top: 12.0, left: 44.0, bottom: 12.0, right: 12.0)
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void))
    {
        if location == nil {
            assistant.getLocation()
        }
        else {
            updateView()
        }
    }
    
//    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
//    {
//        super.touchesBegan(touches, withEvent: event)
//        if let ctx = extensionContext, let url = NSURL(string: "whereabouts://") {
//            ctx.openURL(url, completionHandler: nil)
//        }
//    }
    
}


extension TodayViewController: LocationAssistantDelegate
{
    
    func receivedLocation(location: CLLocation, finished: Bool)
    {
        self.location = location
        
        if finished {
            assistant.getAddressForLocation(location)
        }
    }
    
    func receivedAddress(placemark: CLPlacemark)
    {
        self.placemark = placemark
        activityIndicator.stopAnimating()
    }
    
    func authorizationDenied()
    {
        locationLabel.text = "Location Access Denied."
        altitudeLabel.text = "-"
        activityIndicator.stopAnimating()
    }
    
    func failedToGetLocation()
    {
        if location == nil {
            locationLabel.text = "Could not get a location."
        }
        activityIndicator.stopAnimating()
    }
    
    func failedToGetAddress()
    {
        activityIndicator.stopAnimating()
    }
    
}
