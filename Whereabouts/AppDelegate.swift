
import UIKit
import CoreLocation
import CoreSpotlight

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private let assistant = LocationAssistant()
    private let manager = CLLocationManager()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        if SettingsController.sharedController.shouldMonitorVisits {
            assistant.startVisitsMonitoring()
        }
        
        MenuController.sharedController.setupMenuWithViewController(
            StyledNavigationController(rootViewController: LocationsViewController()),
            andWindow: UIWindow(frame: UIScreen.mainScreen().bounds)
        )
        
        application.registerUserNotificationSettings(
            UIUserNotificationSettings(forTypes: [.Alert, .Sound], categories: nil)
        )
        
        application.registerForRemoteNotifications()
        
        CloudController.sharedController.sync()
        SearchIndexController.sharedController.indexLocations()
        
        if SettingsController.sharedController.fisrtLaunchDate == nil {
            SettingsController.sharedController.fisrtLaunchDate = NSDate()
        }
        
        if !SettingsController.sharedController.hasSubscribed {
            CloudController.sharedController.subscribeToChanges()
        }
        
        PersistentController.sharedController.migrateLegacyData()
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(AppDelegate.settingsDidChange),
            name: kSettingsControllerDidChangeNotification,
            object: nil
        )
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(AppDelegate.visitsDidUpdate),
            name: PersistentController.PersistentControllerVistsDidUpdate,
            object: nil
        )
        
        updateShortcutItems(application)
        manager.delegate = self
        
        return true
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        let minutesSinceLastCloudSync = NSDate().minutesSince(SettingsController.sharedController.lastCloudSync)
        if minutesSinceLastCloudSync > 14 {
            CloudController.sharedController.sync()
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        CloudController.sharedController.handleNotificationInfo(userInfo, completion: completionHandler)
    }
    
    // MARK: - NSUserActivity
    
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        if userActivity.activityType == CSSearchableItemActionType {
            guard let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
                return false
            }
            
            let locations = PersistentController.sharedController.locations()
            
            let index = locations.indexOf { location in
                return location.identifier == identifier
            }
            
            guard let indexOfLocation = index else {
                return false
            }
            
            let location = locations[indexOfLocation]
            
            let nvc = StyledNavigationController(rootViewController: DetailViewController(location: location))
            
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                nvc.modalPresentationStyle = .FormSheet
            }
            
            MenuController.sharedController.presenterViewController?.presentViewController(
                nvc,
                animated: true,
                completion: nil
            )
            
            return true
        }
        
        return false
    }
    
    // MARK: - Quick Actions
    
    private func handleShortcutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
        if let type = shortcutItem.type.componentsSeparatedByString(".").last {
            if type == "Add" {
                MenuController.sharedController.presenterViewController?.presentViewController(
                    StyledNavigationController(rootViewController: EditViewController(location: nil, isCurrentLocation: true)),
                    animated: true,
                    completion: nil
                )
            }
            else if type == "Search" {
                let nvc = StyledNavigationController(rootViewController: AddViewController())
                nvc.lowPowerCapable = true
                MenuController.sharedController.presenterViewController?.presentViewController(
                    nvc,
                    animated: true,
                    completion: nil
                )
            }
            else if type == "Visits" {
                var locationFromVisit: Location?
                if let locationData = shortcutItem.userInfo?["location"] as? NSData, let location = NSKeyedUnarchiver.unarchiveObjectWithData(locationData) as? CLLocation {
                    locationFromVisit = Location(location: location)
                }
                
                MenuController.sharedController.presenterViewController?.presentViewController(
                    StyledNavigationController(rootViewController: EditViewController(location: locationFromVisit, isCurrentLocation: false)),
                    animated: true,
                    completion: nil
                )
            }
            else {
                return false
            }
        }
        
        return false
    }
    
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        completionHandler(handleShortcutItem(shortcutItem))
    }
    
    func updateShortcutItems(application: UIApplication) {
        var items = [UIApplicationShortcutItem]()
        
        if let currentLocationItem = currentLocationShortcutItem() {
            items.append(currentLocationItem)
        }
        
        if let visitItem = visitShortcutItem() where SettingsController.sharedController.shouldMonitorVisits {
            items.append(visitItem)
        }
        
        if items.count > 0 {
            application.shortcutItems = items
        }
    }
    
    func visitShortcutItem() -> UIApplicationShortcutItem? {
        if let latestVisit = PersistentController.sharedController.visits().last {
            var icon: UIApplicationShortcutIcon
            if #available(iOS 9.1, *) {
                icon = UIApplicationShortcutIcon(type: .MarkLocation)
            } else {
                icon = UIApplicationShortcutIcon(templateImageName: "action-pin")
            }
            
            return UIApplicationShortcutItem(
                type: "\(NSBundle.mainBundle().bundleIdentifier).Visits",
                localizedTitle: "Last Visit",
                localizedSubtitle: latestVisit.address?.fullFormatedString() ?? latestVisit.coordinate.formattedString(),
                icon: icon,
                userInfo: ["location": NSKeyedArchiver.archivedDataWithRootObject(latestVisit.location)]
            )
        }
        else {
            return nil
        }
    }
    
    func currentLocationShortcutItem() -> UIApplicationShortcutItem? {
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus == .AuthorizedAlways || authStatus == .AuthorizedWhenInUse {
            return UIApplicationShortcutItem(
                type: "\(NSBundle.mainBundle().bundleIdentifier).Add",
                localizedTitle: "Current Location",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(type: .Location),
                userInfo: nil
            )
        }
        else {
            return nil
        }
    }
    
    // MARK: - Notifications
    
    @objc private func visitsDidUpdate() {
        if SettingsController.sharedController.shouldMonitorVisits {
            updateShortcutItems(UIApplication.sharedApplication())
        }
    }
    
    @objc private func settingsDidChange() {
        if SettingsController.sharedController.shouldMonitorVisits {
            assistant.startVisitsMonitoring()
        }
        else {
            assistant.terminate()
        }
    }

}

extension AppDelegate: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
            
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            updateShortcutItems(UIApplication.sharedApplication())
            
        default: break
            
        }
    }
    
}

