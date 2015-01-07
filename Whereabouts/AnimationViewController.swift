//
//  AnimationViewController.swift
//  Whereabouts
//
//  Created by Ryan Ackermann on 12/30/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

import UIKit

enum AnimationType {
    case Delete, Retry
}

class AnimationViewController: UIViewController {

    @IBOutlet weak var infoLabel: UILabel!
    let gradient: CAGradientLayer = CAGradientLayer()
    
    // Gradient Arrays
    let darkColors = [UIColor(hex: 0x34495e).CGColor, UIColor(hex: 0x2c3e50).CGColor]
    let greenColors = [UIColor(hex: 0x2ecc71).CGColor, UIColor(hex: 0x27ae60).CGColor]
    let redColors = [UIColor(hex: 0xe74c3c).CGColor, UIColor(hex: 0xc0392b).CGColor]
    let yellowColors = [UIColor(hex: 0xf1c40f).CGColor, UIColor(hex: 0xf39c12).CGColor]
    let blueColors = [UIColor(hex: 0x00b9ff).CGColor, UIColor(hex: 0x007aff).CGColor]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.infoLabel.text = ""
        gradient.frame = self.view.frame
        gradient.locations = [0, 0.7]
        gradient.colors = darkColors
        self.view.layer.insertSublayer(gradient, atIndex: 0)
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func showVCAfter(type: AnimationType, after: Double) {
        if type == .Delete {
            self.animateViewToColor(redColors, duration: 0.345)
            self.infoLabel.text = "Deleting..."
            delay(after) {
                var pageVC = self.storyboard?.instantiateViewControllerWithIdentifier("RAPageViewController") as RAPageViewController
                pageVC.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
                self.presentViewController(pageVC, animated: true, completion: nil)
            }
        } else if type == .Retry {
            self.animateViewToColor(yellowColors, duration: 0.345)
            self.infoLabel.text = "Resetting..."
            delay(after) {
                var pageVC = self.storyboard?.instantiateViewControllerWithIdentifier("RAPageViewController") as RAPageViewController
                pageVC.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
                self.presentViewController(pageVC, animated: true, completion: nil)
            }
        }
    }
    
    func animateViewToColor(colors: Array<CGColor!>, duration: NSTimeInterval) {
        UIView.animateWithDuration(duration, delay: 0.0, options: .CurveEaseInOut, animations: { ()
            CATransaction.begin()
            CATransaction.setAnimationDuration(duration)
            
            self.gradient.colors = colors
            
            CATransaction.commit()
            }, completion: { _ in
                // Animation did end callback
        })
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
