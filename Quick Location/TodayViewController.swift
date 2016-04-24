
import UIKit
import NotificationCenter
import CoreLocation


class TodayViewController: UIViewController, NCWidgetProviding {
    
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
    
    let assistant = LocationAssistant()
    //let sharedDefaults = NSUserDefaults(suiteName: "group.net.naturaln0va.Whereabouts")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assistant.delegate = self
        
        locationLabel.text = "Locating..."
        altitudeLabel.text = "-"
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(TodayViewController.relocate))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if location == nil {
            assistant.getLocation()
        }
        else {
            updateView()
        }
    }
    
    func relocate() {
        locationLabel.text = "Locating..."
        altitudeLabel.text = "-"

        location = nil
        placemark = nil
        activityIndicator.startAnimating()
        assistant.getLocation()
    }
    
    func updateView() {
        guard let location = location else {
            return
        }
        locationLabel.text = location.coordinate.formattedString()
        altitudeLabel.text = "\(location.altitude.formattedString()) \(location.altitude > 0 ? " above sea level" : " below sea level")"
        
        guard let address = placemark else {
            return
        }
        locationLabel.text = address.fullFormatedString()
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: 12.0, left: 44.0, bottom: 12.0, right: 12.0)
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
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


extension TodayViewController: LocationAssistantDelegate {
    
    func locationAssistantReceivedLocation(location: CLLocation, finished: Bool) {
        self.location = location
        
        if finished {
            assistant.getAddressForLocation(location)
        }
    }
    
    func locationAssistantReceivedAddress(placemark: CLPlacemark) {
        self.placemark = placemark
        activityIndicator.stopAnimating()
    }
    
    func locationAssistantAuthorizationDenied() {
        locationLabel.text = "Location Access Denied."
        altitudeLabel.text = "-"
        activityIndicator.stopAnimating()
    }
    
    func locationAssistantFailedToGetLocation() {
        if location == nil {
            locationLabel.text = "Could not get a location."
        }
        activityIndicator.stopAnimating()
    }
    
    func locationAssistantFailedToGetAddress() {
        activityIndicator.stopAnimating()
    }
        
}
