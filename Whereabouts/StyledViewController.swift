
import UIKit

class StyledViewController: UIViewController {
    
    init() {
        super.init(nibName: NSStringFromClass(self.dynamicType).componentsSeparatedByString(".").last!, bundle: NSBundle.mainBundle())
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}
