
import Foundation

let kSettingsControllerDidChangeNotification: String = "settingsControllerDidChange"


class SettingsController {
    
    static let sharedController = SettingsController()
    
    static let kShouldMonitorVisits = "shouldMonitorVisits" // user preference
    static let kUserFirstLaunchedKey = "firstLaunched" // date user first installed
    static let kUserHasSubscribedKey = "userSubscribed" // user has subscribed to cloud changes
    static let kCloudSyncKey = "cloudSync" // user watns backups to iCloud
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    
    lazy private var baseDefaults: [String: AnyObject] = {
        return [
            kShouldMonitorVisits: false,
            kUserHasSubscribedKey: false,
            kCloudSyncKey: true
        ]
    }()
    
    // MARK: - Init
    init() {
        loadSettings()
    }
    
    // MARK: - Private
    private func loadSettings() {
        defaults.registerDefaults(baseDefaults)
    }
    
    // MARK: - Public
    
    var shouldSyncToCloud: Bool {
        get {
            return defaults.boolForKey(SettingsController.kCloudSyncKey)
        }
        set {
            defaults.setBool(newValue, forKey: SettingsController.kCloudSyncKey)
            defaults.synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName(kSettingsControllerDidChangeNotification, object: nil)
        }
    }
    
    var shouldMonitorVisits: Bool {
        get {
            return defaults.boolForKey(SettingsController.kShouldMonitorVisits)
        }
        set {
            defaults.setBool(newValue, forKey: SettingsController.kShouldMonitorVisits)
            defaults.synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName(kSettingsControllerDidChangeNotification, object: nil)
        }
    }
    
    var hasSubscribed: Bool {
        get {
            return defaults.boolForKey(SettingsController.kUserHasSubscribedKey)
        }
        set {
            defaults.setBool(newValue, forKey: SettingsController.kUserHasSubscribedKey)
            defaults.synchronize()
        }
    }
    
    var fisrtLaunchDate: NSDate? {
        get {
            let launchTimeInterval = defaults.doubleForKey(SettingsController.kUserFirstLaunchedKey)
            if launchTimeInterval == 0 {
                return nil
            }
            else {
                return NSDate(timeIntervalSince1970: launchTimeInterval)
            }
        }
        set {
            defaults.setDouble(NSDate().timeIntervalSince1970, forKey: SettingsController.kUserFirstLaunchedKey)
        }
    }
    
}
