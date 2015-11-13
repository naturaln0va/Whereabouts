//
//  Created by Ryan Ackermann on 5/29/15.
//  Copyright (c) 2015 Ryan Ackermann. All rights reserved.
//

import UIKit

class RHAViewController: UIViewController
{
    init()
    {
        super.init(nibName: NSStringFromClass(self.dynamicType).componentsSeparatedByString(".").last!, bundle: NSBundle.mainBundle())
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
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
