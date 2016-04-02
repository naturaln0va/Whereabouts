
import UIKit


@objc protocol LocationAccessViewControllerDelegate {
    optional func locationAccessViewControllerAccessGranted()
    optional func locationAccessViewControllerAccessDenied()
}


class LocationAccessViewController: UIViewController {
    
    var delegate: LocationAccessViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 0.239,  green: 0.239,  blue: 0.239, alpha: 1.0)
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
