
import UIKit

class MenuController: NSObject
{
    static let sharedController = MenuController()
    
    private(set) var presenterViewController: UIViewController?
    private(set) var window: UIWindow?
    
    static func setupMenuWithViewController(viewController: UIViewController, andWindow window: UIWindow) {
        sharedController.presenterViewController = viewController
        sharedController.window = window
        sharedController.window?.rootViewController = viewController
        window.makeKeyAndVisible()
    }
    
}
