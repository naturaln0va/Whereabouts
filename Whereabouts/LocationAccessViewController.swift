
import UIKit


protocol LocationAccessViewControllerDelegate {
    func accessGranted()
    func accessDenied()
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
            delegate.accessGranted()
        }
        dismiss()
    }
    
    @IBAction func noThanksButtonPressed(sender: AnyObject) {
        if let delegate = delegate {
            delegate.accessDenied()
        }
        dismiss()
    }
    
}
