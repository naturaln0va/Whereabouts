
import UIKit


class StyledNavigationController: UINavigationController
{

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        navigationBar.barTintColor = ColorController.navBarBackgroundColor
        navigationBar.tintColor = ColorController.navBarTintColor
        navigationBar.translucent = true
        
        navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: ColorController.navBarTintColor,
            NSFontAttributeName: UIFont.systemFontOfSize(17, weight: UIFontWeightMedium)
        ]
    }
    
    override func prefersStatusBarHidden() -> Bool
    {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle
    {
        return .LightContent
    }
    
}
