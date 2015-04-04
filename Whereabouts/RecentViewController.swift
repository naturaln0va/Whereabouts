//
//  RecentViewController.swift
//  Whereabouts
//
//  Created by Ryan Ackermann on 10/22/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

import UIKit
import AudioToolbox

class RecentViewController: UIViewController {
    
    var locationLabel: UILabel!
    var coordLabel: UILabel!
    var timeStampLabel: UILabel!
    var deleteButton: UIButton!
    
    var recentLocation: Recent!
    
    // Sound ID's
    var tapAudioEffect: SystemSoundID = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clearColor()
        initSound()
        initUIElements()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        locationLabel.text = recentLocation.longLocationDescription(recentLocation.placemark)
        coordLabel.text = "\(recentLocation.placemark.location.coordinate.latitude), \(recentLocation.placemark.location.coordinate.longitude)"
        timeStampLabel.text = recentLocation.relativeStringForDate(recentLocation.timeStamp)
        
        UIView.animateWithDuration(0.64, delay: 0.0, options: .CurveEaseIn, animations: { _ in
            self.deleteButton.alpha = 1.0
            }, completion: { _ in
        })
    }
    
    func initSound() {
        var tapSoundPath = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Satisfying Click", ofType: "wav")!)
        //var locationSoundPath = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Satisfying Click", ofType: "wav")!)
        
        AudioServicesCreateSystemSoundID(tapSoundPath! as CFURLRef, &tapAudioEffect)
        //AudioServicesCreateSystemSoundID(locationSoundPath! as CFURLRef, &locationAudioEffect)
    }
    
    func initUIElements() {
        if RADevice.getDeviceName() == "iPhone4" {
            locationLabel = UILabel(frame: CGRectMake(CGRectGetMidX(view.frame) - 310 / 2, 35, 310, 155))
            locationLabel.font = UIFont(name: "Berlin", size: 37.0)
            locationLabel.numberOfLines = 0
            locationLabel.lineBreakMode = .ByWordWrapping
            locationLabel.textAlignment = .Center
            locationLabel.textColor = UIColor.whiteColor()
            view.addSubview(locationLabel)
        } else {
            locationLabel = UILabel(frame: CGRectMake(CGRectGetMidX(view.frame) - 310 / 2, 120, 310, 155))
            locationLabel.font = UIFont(name: "Berlin", size: 37.0)
            locationLabel.numberOfLines = 0
            locationLabel.lineBreakMode = .ByWordWrapping
            locationLabel.textAlignment = .Center
            locationLabel.textColor = UIColor.whiteColor()
            view.addSubview(locationLabel)
        }
        
        coordLabel = UILabel(frame: CGRect(x: CGRectGetMidX(view.frame) - 310 / 2, y: locationLabel.frame.origin.y + CGRectGetHeight(locationLabel.frame) + 25, width: 310, height: 95))
        coordLabel.font = UIFont(name: "Berlin", size: 23.0)
        coordLabel.numberOfLines = 0
        coordLabel.lineBreakMode = .ByWordWrapping
        coordLabel.textAlignment = .Center
        coordLabel.textColor = UIColor.whiteColor()
        view.addSubview(coordLabel)
        
        deleteButton = UIButton(frame: CGRect(x: CGRectGetMidX(view.frame) - 50 / 2, y: coordLabel.frame.origin.y + CGRectGetHeight(coordLabel.frame) + 5, width: 50, height: 50))
        deleteButton.setBackgroundImage(UIImage(named: "Delete"), forState: .Normal)
        deleteButton.addTarget(self, action: Selector("deleteAction:"), forControlEvents: .TouchDown)
        deleteButton.alpha = 0.05
        view.addSubview(deleteButton)
        
        timeStampLabel = UILabel(frame: CGRectMake(CGRectGetMidX(view.frame) - 250 / 2, CGRectGetHeight(view.frame) - 80, 250, 45))
        timeStampLabel.font = UIFont(name: "Berlin", size: 23.0)
        timeStampLabel.numberOfLines = 0
        timeStampLabel.lineBreakMode = .ByWordWrapping
        timeStampLabel.textAlignment = .Center
        timeStampLabel.textColor = UIColor.whiteColor()
        view.addSubview(timeStampLabel)
    }
    
    func deleteAction(sender:UIButton!) {
        AudioServicesPlaySystemSound(tapAudioEffect)
        let alertController = UIAlertController(title: "Delete Location?", message: "This cannot be undone.", preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { _ in
            println("Crisis Averted :)")
        }
        alertController.addAction(cancelAction)
        
        let destroyAction = UIAlertAction(title: "Delete", style: .Destructive) { _ in
            let parent = self.parentViewController as RAPageViewController
            parent.deleteData(self.recentLocation)
            
            var animationVC = self.storyboard?.instantiateViewControllerWithIdentifier("AnimationViewController") as AnimationViewController
            animationVC.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
            self.presentViewController(animationVC, animated: true, completion: { 
                animationVC.showVCAfter(.Delete, after: 1.2)
            })
            
        }
        
        alertController.addAction(destroyAction)
        
        self.presentViewController(alertController, animated: true) {
            // ...
        }
    }
    
}
