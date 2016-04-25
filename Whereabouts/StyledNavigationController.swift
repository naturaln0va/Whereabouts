
import UIKit

class StyledNavigationController: UINavigationController {
    
    var lowPowerCapable = true
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.shadowImage = UIImage()
        navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        
        toolbar.clipsToBounds = true
        navigationBar.translucent = false
                
        refreshColors()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return StyleController.sharedController.statusBarStyle
    }
    
    // MARK: - Helpers
    private func refreshColors() {
        let primaryColor = StyleController.sharedController.mainTintColor
        
        navigationBar.barTintColor = primaryColor
        navigationBar.tintColor = StyleController.sharedController.navBarTintColor.colorWithAlphaComponent(0.65)
        
        navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: StyleController.sharedController.navBarTintColor
        ]
    }
    
}
