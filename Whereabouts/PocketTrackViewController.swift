
import UIKit
import CoreLocation

class PocketTrackViewController: UIViewController {

    @IBOutlet private weak var toggleSwitch: UISwitch!
    @IBOutlet private weak var accessDeniedView: UIView!
    
    private let manager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Pocket Track"
        
        manager.delegate = self
        toggleSwitch.on = SettingsController.sharedController.shouldMonitorVisits
        
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus != .AuthorizedAlways {
            manager.requestAlwaysAuthorization()
            accessDeniedView.hidden = false
        }
        else {
            accessDeniedView.hidden = true
        }
    }

    @IBAction func toggleSwitchPressed(sender: UISwitch) {
        SettingsController.sharedController.shouldMonitorVisits = sender.on
    }
    
    @IBAction func openSettingsButtonPressed() {
        if let url = NSURL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
}

extension PocketTrackViewController: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .AuthorizedAlways:
            accessDeniedView.hidden = true
            
        default:
            accessDeniedView.hidden = false
        }
    }
    
}