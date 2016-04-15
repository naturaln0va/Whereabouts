
import Foundation

let kSettingsControllerDidChangeNotification: String = "settingsControllerDidChange"


class SettingsController {
    
    static let sharedController = SettingsController()
    
    static let kNearbyPhotoRangeKey = "nearbyPhotoRange" // meters
    static let kUnitStyleKey = "unitStyle" // customary, metric
    static let kShouldMonitorVisits = "shouldMonitorVisits" // user preference
    static let kUserFirstLaunchedKey = "firstLaunched" // date user first installed
    static let kUserHasSubscribedKey = "userSubscribed" // user has subscribed to cloud changes
    static let kBatterySaverModeKey = "batterySaver" // user wants to save energy so let make location fixes less accurate
    static let kCloudSyncKey = "cloudSync" // user watns backups to iCloud
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    
    lazy private var baseDefaults: [String: AnyObject] = {
        return [
            kNearbyPhotoRangeKey: 250,
            kUnitStyleKey: true,
            kShouldMonitorVisits: false,
            kUserHasSubscribedKey: false,
            kBatterySaverModeKey: false,
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
    func stringForPhotoRange() -> String {
        switch nearbyPhotoRange {
        case 50:
            return isUnitStyleImperial ? "165ft" : "50m"
            
        case 250:
            return isUnitStyleImperial ? "825ft" : "250m"
            
        case 1600:
            return isUnitStyleImperial ? "1mi" : "1.6km"
            
        case 5000:
            return isUnitStyleImperial ? "3mi" : "5km"
            
        default:
            return ""
        }
    }
    
    var nearbyPhotoRange: Int {
        get {
            return defaults.integerForKey(SettingsController.kNearbyPhotoRangeKey)
        }
        set {
            defaults.setInteger(newValue, forKey: SettingsController.kNearbyPhotoRangeKey)
            defaults.synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName(kSettingsControllerDidChangeNotification, object: nil)
        }
    }
    
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
    
    var batterySaverMode: Bool {
        get {
            return defaults.boolForKey(SettingsController.kBatterySaverModeKey)
        }
        set {
            defaults.setBool(newValue, forKey: SettingsController.kBatterySaverModeKey)
            defaults.synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName(kSettingsControllerDidChangeNotification, object: nil)
        }
    }
    
    var isUnitStyleImperial: Bool {
        get {
            return defaults.boolForKey(SettingsController.kUnitStyleKey)
        }
        set {
            defaults.setBool(newValue, forKey: SettingsController.kUnitStyleKey)
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
