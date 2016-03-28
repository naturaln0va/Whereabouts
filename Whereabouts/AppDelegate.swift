
import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var assistant = LocationAssistant(viewController: nil)

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        MenuController.setupMenuWithViewController(
            StyledNavigationController(rootViewController: LocationsViewController()),
            andWindow: UIWindow(frame: UIScreen.mainScreen().bounds)
        )
        
        let notificationSettings = UIUserNotificationSettings(
            forTypes: .Alert,
            categories: nil
        )
        
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
        
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
    
    internal func settingsDidChange() {
        if SettingsController.sharedController.shouldMonitorVisits {
            assistant.startVisitsMonitoring()
        }
        else {
            assistant.terminate()
        }
    }

}

