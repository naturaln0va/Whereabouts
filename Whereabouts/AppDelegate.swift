
import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{

    var window: UIWindow?
    var assistant = LocationAssistant(viewController: nil)

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        
        let notificationSettings = UIUserNotificationSettings(
            forTypes: .Alert,
            categories: nil
        )
        
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
        
        PersistentController.sharedController.migrateLegacyData()
        PersistentController.sharedController.cleanUpVisits()
        
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
            assistant.startVisitsMonitoring()
        }
        
        return true
    }
    
    internal func settingsDidChange()
    {
        if SettingsController.sharedController.shouldMonitorVisits {
            assistant.startVisitsMonitoring()
        }
        else {
            assistant.terminate()
        }
    }

}

