
import UIKit


@objc protocol LocationAccessViewControllerDelegate {
    optional func locationAccessViewControllerAccessGranted()
    optional func locationAccessViewControllerAccessDenied()
}


class LocationAccessViewController: StyledViewController {
    
    var delegate: LocationAccessViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    private func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func accessButtonPressed(sender: AnyObject) {
        if let delegate = delegate {
            delegate.locationAccessViewControllerAccessGranted?()
        }
        dismiss()
    }
    
    @IBAction func noThanksButtonPressed(sender: AnyObject) {
        if let delegate = delegate {
            delegate.locationAccessViewControllerAccessDenied?()
        }
        dismiss()
    }
    
}
