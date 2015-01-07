//
//  TodayViewController.swift
//  Quick Location
//
//  Created by Ryan Ackermann on 10/27/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

import UIKit
import NotificationCenter
import CoreLocation

class TodayViewController: UIViewController, NCWidgetProviding, CLLocationManagerDelegate {
        
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var updatedLabel: UILabel!
    
    let locationManager = CLLocationManager()
    var location: CLLocation!
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    
    let sharedDefaults = NSUserDefaults(suiteName: "group.net.naturaln0va.Whereabouts")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let locationString = sharedDefaults?.objectForKey("location") as? String {
            locationLabel.text = locationString
        }
        if let date = sharedDefaults?.objectForKey("date") as? NSDate {
            updatedLabel.text = "Updated \(relativeStringForDate(date))"
        }
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5.0, left: 42.0, bottom: 5.0, right: 5.0)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as? UITouch
        let point = touch!.locationInView(self.view)
        
        for touch in touches {
            if CGRectContainsPoint(locationLabel.frame, point) {
                extensionContext?.openURL(NSURL(string: "whereabouts://more")!, completionHandler: nil)
            }
        }
    }
    
    func relativeStringForDate(date: NSDate) -> String {
        let units:NSCalendarUnit = .CalendarUnitMinute | .CalendarUnitHour | .CalendarUnitDay | .CalendarUnitWeekOfYear |
            .CalendarUnitMonth | .CalendarUnitYear
        
        // if "date" is before "now" (i.e. in the past) then the components will be positive
        let components: NSDateComponents = NSCalendar.currentCalendar().components(units, fromDate: date, toDate: NSDate(), options: nil)
        
        if components.year > 0 {
            return "\(components.year) years ago"
        } else if components.month > 0 {
            if components.month > 1 {
                return "\(components.month) months ago"
            } else {
                return "last month"
            }
        } else if components.weekOfYear > 0 {
            if components.weekOfYear > 1 {
                return "\(components.weekOfYear) weeks ago"
            } else {
                return "last week"
            }
        } else if components.day > 0 {
            if components.day > 1 {
                return "\(components.day) days ago"
            } else {
                return "yesterday"
            }
        } else {
            if components.hour > 0 {
                if components.hour > 1 {
                    return "\(components.hour) hours ago"
                } else {
                    return "1 hour ago"
                }
            } else if components.minute > 1 {
                if components.minute == 1 {
                    return "1 minute ago"
                } else {
                    return "\(components.minute) minuts ago"
                }
            } else {
                return "a moment ago"
            }
        }
    }

}
