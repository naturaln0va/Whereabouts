
import UIKit
import CoreLocation

class LocationsViewController: UIViewController, LocationAssistantDelegate
{
    private let assistant = LocationAssistant()
    private var currentLocation: CLLocation?
    
    private lazy var locationStatusView: UIView =  {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0x067dff) //Error red color UIColor(hex: 0xc03b2b)
        
        let infoLabel = UILabel()
        infoLabel.text = "Locating..."
        infoLabel.textColor = UIColor.whiteColor()
        infoLabel.textAlignment = .Center
        infoLabel.font = UIFont.systemFontOfSize(12)
        infoLabel.sizeToFit()
        
        view.frame = infoLabel.frame
        view.addSubview(infoLabel)
        
        infoLabel.center = view.center
        
        view.layer.cornerRadius = 12.0
        
        view.frame.origin.y = CGRectGetHeight(self.view.bounds) - 40
        
        return view
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        title = "Locations"
        view.backgroundColor = ColorController.viewControllerBackgroundColor
        
        let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "locateBarButtonWasPressed")
        let leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Settings-BarButton"), style: .Plain, target: self, action: "settingsBarButtonWasPressed")
        
        navigationItem.rightBarButtonItem = rightBarButtonItem
        navigationItem.leftBarButtonItem = leftBarButtonItem
        
        assistant.delegate = self
    }
    
    // MARK: - BarButon Actions
    func locateBarButtonWasPressed()
    {
        assistant.getLocation()
        showLocationStatus()
    }
    
    func settingsBarButtonWasPressed()
    {
        
    }
    
    // MARK: - Private Helpers
    private func showLocationStatus()
    {
        view.addSubview(locationStatusView)
        UIView.animateWithDuration(0.125, delay: 0.0, usingSpringWithDamping: 0.25, initialSpringVelocity: 5.0, options: .CurveEaseOut, animations: { () -> Void in
            self.locationStatusView.frame.origin.y = self.view.center.y
        }, completion: nil)
    }
    
    private func dismissLocationStatusWithCompletion(completion: Void -> Void)
    {
        
    }
    
    private func showSaveLocationViewController()
    {
        let newLocationVC = NewLocationViewController()
        
        newLocationVC.location = assistant.location
        newLocationVC.placemark = assistant.placemark
        
        presentViewController(RHANavigationViewController(rootViewController: newLocationVC), animated: true, completion: nil)
    }
    
    // MARK: - LocationAssistantDelegate Delegate
    func receivedLocation(location: CLLocation, finished: Bool)
    {
        if finished {
            currentLocation = location
            assistant.getAddressForLocation(location)
        }
    }
    
    func receivedAddress(placemark: CLPlacemark)
    {
        dismissLocationStatusWithCompletion {
            self.showSaveLocationViewController()
        }
    }
    
    func failedToGetAddress()
    {
        dismissLocationStatusWithCompletion {
            self.showSaveLocationViewController()
        }
    }
    
    func failedToGetLocation()
    {
        dismissLocationStatusWithCompletion {
            self.showSaveLocationViewController()
        }
    }
    
    func authorizationDenied()
    {
        dismissLocationStatusWithCompletion {
            self.showSaveLocationViewController()
        }
    }
}
