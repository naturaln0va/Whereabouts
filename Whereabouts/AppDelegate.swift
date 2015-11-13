
import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        PersistenceController.sharedController.initializeCoreData()
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        if let window = window {
            MenuController.sharedController.showInWindow(window)
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication)
    {
        PersistenceController.sharedController.save()
    }

    func applicationDidEnterBackground(application: UIApplication)
    {
        PersistenceController.sharedController.save()
    }

    func applicationWillTerminate(application: UIApplication)
    {
        PersistenceController.sharedController.save()
    }

}

