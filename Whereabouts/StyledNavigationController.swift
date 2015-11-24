
import UIKit


class StyledNavigationController: UINavigationController
{

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        navigationBar.barTintColor = ColorController.backgroundColor
        navigationBar.tintColor = ColorController.navBarBackgroundColor
        navigationBar.translucent = true
        
        navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.blackColor(),
            NSFontAttributeName: UIFont.systemFontOfSize(17, weight: UIFontWeightMedium)
        ]
    }
    
    override func prefersStatusBarHidden() -> Bool
    {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle
    {
        return .Default
    }
    
}
