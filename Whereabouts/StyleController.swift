
import UIKit


class StyleController {
    
    static let sharedController = StyleController()
    
    lazy var navBarTintColor = UIColor(white: 1.0, alpha: 1.0)
    lazy var backgroundColor = UIColor(red: 0.94,  green: 0.94,  blue: 0.96, alpha: 1.0)
    lazy var mainTintColor = UIColor(red: 0.35, green: 0.55,  blue: 0.98, alpha: 1.0)
    lazy var lowPowerColor = UIColor(red: 0.298,  green: 0.850,  blue: 0.390, alpha: 1.0)
    
    lazy var statusBarStyle: UIStatusBarStyle = .LightContent
    
}
