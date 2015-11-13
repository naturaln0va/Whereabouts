//
//  Created by Ryan Ackermann on 5/29/15.
//  Copyright (c) 2015 Ryan Ackermann. All rights reserved.
//

import UIKit

class RHANavigationViewController: UINavigationController
{

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        navigationBar.barTintColor = ColorController.navBarBackgroundColor
        navigationBar.tintColor = ColorController.navBarTintColor
        
        navigationBar.layer.shadowColor = ColorController.navBarSeperatorColor.CGColor
        navigationBar.layer.shadowOffset = CGSize(width: 0, height: 4)
        navigationBar.layer.shadowRadius = 0
        navigationBar.layer.shadowPath = UIBezierPath(rect: navigationBar.frame).CGPath
        navigationBar.layer.shadowOpacity = 1.0
        navigationBar.layer.masksToBounds = true
        navigationBar.clipsToBounds = false

        
        navigationBar.translucent = false
        
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
