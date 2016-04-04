
import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var assistant = LocationAssistant(viewController: nil)

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        MenuController.setupMenuWithViewController(
            StyledNavigationController(rootViewController: LocationsViewController()),
            andWindow: UIWindow(frame: UIScreen.mainScreen().bounds)
        )
        
        application.registerForRemoteNotifications()
        
        CloudController.sharedController.sync()
        if SettingsController.sharedController.fisrtLaunchDate == nil {
            SettingsController.sharedController.fisrtLaunchDate = NSDate()
        }
        
        if !SettingsController.sharedController.hasSubscribed {
            CloudController.sharedController.subscribeToChanges()
        }
        
        StyleController.sharedController
        
        PersistentController.sharedController.migrateLegacyData()
        PersistentController.sharedController.cleanUpVisits()
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(AppDelegate.settingsDidChange),
            name: kSettingsControllerDidChangeNotification,
            object: nil
        )
        
        if SettingsController.sharedController.shouldMonitorVisits {
            assistant.startVisitsMonitoring()
        }
        
        return true
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {        
        CloudController.sharedController.handleNotificationInfo(userInfo, completion: completionHandler)
    }
    
    // MARK: - Quick Actions
    
    private func handleShortcutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
        if let type = shortcutItem.type.componentsSeparatedByString(".").last {
            if type == "Add" {
                MenuController.sharedController.presenterViewController?.presentViewController(
                    StyledNavigationController(rootViewController: EditViewController(location: nil)),
                    animated: true,
                    completion: nil
                )
            }
            else if type == "Search" {
                MenuController.sharedController.presenterViewController?.presentViewController(
                    StyledNavigationController(rootViewController: AddViewController()),
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
    
    // MARK: - Notifications
    
    internal func settingsDidChange() {
        if SettingsController.sharedController.shouldMonitorVisits {
            assistant.startVisitsMonitoring()
        }
        else {
            assistant.terminate()
        }
    }

}

