
import UIKit

class MenuController: NSObject
{
    static let sharedController = MenuController()
    
    private var presenterViewController: UIViewController?
    private var window = UIWindow()
    
    lazy var locationsNC: RHANavigationViewController = {
        return RHANavigationViewController(rootViewController: LocationsViewController())
    }()
    
    override init()
    {
        super.init()
    }
    
    func showInWindow(window: UIWindow)
    {
        presenterViewController = SplashViewController()
        
        self.window = window
        window.rootViewController = presenterViewController
        window.makeKeyAndVisible()
        
        if let presenterVC = presenterViewController {
            delay(0.5) {
                presenterVC.presentViewController(self.locationsNC, animated: false, completion: nil)
            }
        }
    }
}
