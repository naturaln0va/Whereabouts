//
//  RAPageViewController.swift
//  Whereabouts
//
//  Created by Ryan Ackermann on 10/22/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class RAPageViewController: UIPageViewController, UIPageViewControllerDataSource {
    
    var pages: [NSManagedObject]!
    var pageNavigationIndicies = [0, -1]
    let gradient: CAGradientLayer = CAGradientLayer()
    var mainViewController: MainViewController!
    let darkColors = [UIColor(hex: 0x34495e).CGColor, UIColor(hex: 0x2c3e50).CGColor]
    
    override func viewDidLoad() {
        self.pages = []
        
        gradient.frame = self.view.frame
        gradient.locations = [0, 0.7]
        gradient.colors = darkColors
        self.view.layer.insertSublayer(gradient, atIndex: 0)
        
        self.mainViewController = self.storyboard?.instantiateViewControllerWithIdentifier("MainViewController") as MainViewController
        
        self.setViewControllers([mainViewController], direction: .Forward, animated: false, completion: nil)
        
        self.dataSource = self // set to nil to disable
    }
    
    override func viewWillAppear(animated: Bool) {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName: "Location")
        
        var error: NSError?
        
        let fetchResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as [NSManagedObject]?
        
        if let results = fetchResults {
            pages = results
        } else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // MARK: - Model Interaction
    
    func addPage(recent: Recent) {
        let city = recent.placemark.locality
        let state = recent.placemark.administrativeArea
//        for p in pages {
//            let place = p.valueForKey("placemark") as CLPlacemark
//            if place.locality == city && place.administrativeArea == state {
//                println("Location is too similar")
//                return
//            }
//        }
        saveData(recent)
        self.setViewControllers([mainViewController], direction: .Forward, animated: false, completion: nil)
        println("Added Page")
    }
    
    func findIndexOf(target: CLPlacemark, inside: [NSManagedObject]) -> Int {
        var index = -1
        for t in inside as [AnyObject] {
            index++
            if t.valueForKey("placemark") as CLPlacemark == target {
                return index
            }
        }
        return -1
    }
    
    // MARK: - CoreData
    
    func saveData(recent: Recent) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        
        let managedContext = appDelegate.managedObjectContext!
        
        let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: managedContext)
        
        let location = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        
        location.setValue(recent.timeStamp, forKey: "date")
        location.setValue(recent.placemark, forKey: "placemark")
        
        var error: NSError?
        if !managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        } else  {
            println("Save Successful!")
        }
        
        pages.append(location)
    }
    
    func deleteData(recent: Recent) {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        
        let managedContext = appDelegate.managedObjectContext!
        
        var index = 0
        for page: NSManagedObject in pages {
            if page.valueForKey("placemark") as CLPlacemark == recent.placemark &&
                page.valueForKey("date") as NSDate == recent.timeStamp {
                    pages.removeAtIndex(index)
                    managedContext.deleteObject(page)
            }
            index++
        }
        
        var error: NSError?
        if !managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        } else  {
            println("Save Successful!")
        }
    }
    
    // MARK: - PageView Delegate
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        if let currVC = viewController as? RecentViewController {
            var currIndex = findIndexOf(currVC.recentLocation.placemark, inside: pages) - 1
            println("\(currIndex)")
            if currIndex < 0 {
                return self.storyboard?.instantiateViewControllerWithIdentifier("MainViewController") as MainViewController
            } else {
                let newVC = self.storyboard?.instantiateViewControllerWithIdentifier("RecentViewController") as RecentViewController
                let recent = Recent(placemark: self.pages[currIndex].valueForKey("placemark") as CLPlacemark, timeStamp: self.pages[currIndex].valueForKey("date") as NSDate)
                newVC.recentLocation = recent
                return newVC
            }
        } else if let currVC = viewController as? MainViewController {
            return nil
        } else {
            return nil
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        // GOING THIS WAY!!
        
        if let currVC = viewController as? RecentViewController {
            var currIndex = findIndexOf(currVC.recentLocation.placemark, inside: pages) + 1
            println("\(currIndex)")
            if currIndex >= self.pages.count {
                return nil
            }
            
            let newVC = self.storyboard?.instantiateViewControllerWithIdentifier("RecentViewController") as RecentViewController
            let recent = Recent(placemark: self.pages[currIndex].valueForKey("placemark") as CLPlacemark, timeStamp: self.pages[currIndex].valueForKey("date") as NSDate)
            newVC.recentLocation = recent
            return newVC
        } else if let currVC = viewController as? MainViewController {
            if pages.count > 0 {
                println("First Item")
                let newVC = self.storyboard?.instantiateViewControllerWithIdentifier("RecentViewController") as RecentViewController
                let recent = Recent(placemark: self.pages[0].valueForKey("placemark") as CLPlacemark, timeStamp: self.pages[0].valueForKey("date") as NSDate)
                newVC.recentLocation = recent
                
                return newVC
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
