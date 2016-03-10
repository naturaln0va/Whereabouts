
import UIKit

class MenuController: NSObject
{
    static let sharedController = MenuController()
    
    private var presenterViewController: UIViewController?
    private var window = UIWindow()
    
    lazy var locationsNC: StyledNavigationController = {
        return StyledNavigationController(rootViewController: LocationsViewController())
    }()
    
    override init() {
        super.init()
    }
    
    func showInWindow(window: UIWindow) {
        presenterViewController = self.locationsNC
        
        self.window = window
        window.rootViewController = presenterViewController
        window.makeKeyAndVisible()        
    }
}
