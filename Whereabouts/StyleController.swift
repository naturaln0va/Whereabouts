
import UIKit


class StyleController {
    
    static let sharedController = StyleController()
    
    lazy var navBarTintColor = UIColor(white: 1.0, alpha: 1.0)
    lazy var backgroundColor = UIColor(red: 0.94,  green: 0.94,  blue: 0.96, alpha: 1.0)
    lazy var mainTintColor = UIColor(red: 0.35, green: 0.55,  blue: 0.98, alpha: 1.0)
    
    lazy var statusBarStyle: UIStatusBarStyle = .LightContent
    
    init() {
        let navigationStyle = UINavigationBar.appearance()
        navigationStyle.barTintColor = mainTintColor
        navigationStyle.tintColor = navBarTintColor
        navigationStyle.translucent = false
        navigationStyle.titleTextAttributes = [
            NSForegroundColorAttributeName: navBarTintColor
        ]
    }
}
