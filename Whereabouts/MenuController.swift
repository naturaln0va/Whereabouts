
import UIKit

class MenuController: NSObject
{
    static let sharedController = MenuController()
    
    private(set) var presenterViewController: UIViewController?
    private(set) var window: UIWindow?
    
    func setupMenuWithViewController(viewController: UIViewController, andWindow window: UIWindow) {
        self.window = window
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            let splitVC = StyledSplitViewController()
            
            splitVC.delegate = self
            splitVC.addChildViewController(viewController)
            
            let mapNVC = StyledNavigationController(rootViewController: MapViewController())
            splitVC.addChildViewController(mapNVC)
            
            splitVC.view.backgroundColor = StyleController.sharedController.mainTintColor
            
            presenterViewController = splitVC
            self.window?.rootViewController = splitVC
        }
        else {
            presenterViewController = viewController
            self.window?.rootViewController = viewController
        }
        
        window.makeKeyAndVisible()
    }
    
}

extension MenuController: UISplitViewControllerDelegate {}
