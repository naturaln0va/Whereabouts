
import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{

    var window: UIWindow?
    var assistant: LocationAssistant?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        
        let notificationSettings = UIUserNotificationSettings(
            forTypes: UIUserNotificationType.Alert,
            categories: nil
        )
        
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
        
        PersistentController.sharedController.migrateLegacyData()
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        if let window = window {
            MenuController.sharedController.showInWindow(window)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "settingsDidChange",
            name: kSettingsControllerDidChangeNotification,
            object: nil
        )
        
        if SettingsController.sharedController.shouldMonitorVisits {
            assistant = LocationAssistant(viewController: nil)
            assistant?.startVisitsMonitoring()
        }
        
        return true
    }
    
    internal func settingsDidChange()
    {
        if SettingsController.sharedController.shouldMonitorVisits {
            assistant = LocationAssistant(viewController: nil)
            assistant?.startVisitsMonitoring()
        }
        else {
            assistant?.terminate()
        }
    }

}

