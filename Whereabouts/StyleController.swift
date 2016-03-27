
import UIKit


class StyleController {
    
    static let sharedController = StyleController()
    
    let navBarTintColor = UIColor(white: 1.0, alpha: 1.0)
    let backgroundColor = UIColor(red: 0.906, green: 0.906, blue: 0.906, alpha: 1.0)
    let mainTintColor = UIColor(red: 0.353, green: 0.553,  blue: 0.980, alpha: 1.0)
    
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
