//
//  SplashScreenViewController.swift
//  Whereabouts
//
//  Created by Ryan Ackermann on 1/22/15.
//  Copyright (c) 2015 Ryan Ackermann. All rights reserved.
//

import UIKit
import AudioToolbox

class SplashScreenViewController: UIViewController {
    @IBOutlet weak var name: UILabel!

    var windSoundEffect: SystemSoundID = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var windSoundPath = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Arctic Wind", ofType: "wav")!)
        AudioServicesCreateSystemSoundID(windSoundPath! as CFURLRef, &windSoundEffect)
        
        var scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.toValue = NSNumber(float: 1.2)
        scaleAnimation.duration = 0.2
        scaleAnimation.repeatCount = 0.0
        scaleAnimation.autoreverses = true
        
        UIView.animateWithDuration(2.0, delay: 0.0, options: .AllowUserInteraction | .CurveEaseInOut, animations: { _ in
                self.view.backgroundColor = UIColor.whiteColor()
                self.delay(0.2) {
                    AudioServicesPlaySystemSound(self.windSoundEffect)
                }
            
            }, completion: { _ in
                self.name.layer.addAnimation(scaleAnimation, forKey: nil)
                self.delay(0.1) {
                    UIView.animateWithDuration(2.0, delay: 0.0, options: .AllowUserInteraction | .CurveEaseInOut, animations: { _ in
                    self.view.backgroundColor = UIColor.blackColor()
                        }, completion: { _ in
                        var pageVC = self.storyboard?.instantiateViewControllerWithIdentifier("RAPageViewController") as RAPageViewController
                        pageVC.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
                        self.presentViewController(pageVC, animated: true, completion: nil)
                    })
                }
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}
