
import UIKit

class StyledNavigationController: UINavigationController {
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return StyleController.sharedController.statusBarStyle
    }

}
