
import UIKit

class StyledNavigationController: UINavigationController {
    
    var lowPowerCapable = true
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        navigationBar.tintColor = StyleController.sharedController.navBarTintColor
        
        navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: StyleController.sharedController.navBarTintColor
        ]
    }
    
}
