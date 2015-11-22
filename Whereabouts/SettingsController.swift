
import Foundation

let kSettingsControllerDidChangeNotification: String = "settingsControllerDidChange"


class SettingsController
{
    
    static let sharedController = SettingsController()
    
    static let kLocationAccuracyKey = "distanceAccuracy" // enum constant
    static let kLocationTimeoutKey = "distanceTimeout" // seconds
    static let kNearbyPhotoRangeKey = "nearbyPhotoRange" // meters
    static let kUnitStyleKey = "unitStyle" // customary, metric
    static let kUserFirstLaunchedKey = "firstLaunched" // date user first installed
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    
    lazy private var baseDefaults: Dictionary<String, AnyObject> = {
        return [
            kLocationAccuracyKey : kHorizontalAccuracyAverage,
            kLocationTimeoutKey: kLocationTimeoutNormal,
            kNearbyPhotoRangeKey: 150,
            kUnitStyleKey: true
        ]
    }()
    
    // MARK: - Init
    init()
    {
        loadSettings()
    }
    
    // MARK: - Private
    private func loadSettings()
    {
        defaults.registerDefaults(baseDefaults)
    }
    
    // MARK: - Public
    func stringForDistanceAccuracy() -> String
    {
        switch distanceAccuracy {
            
        case kHorizontalAccuracyPoor:
            return "Poor"
            
        case kHorizontalAccuracyFair:
            return "Fair"
            
        case kHorizontalAccuracyAverage:
            return "Average"
            
        case kHorizontalAccuracyGood:
            return "Good"
            
        case kHorizontalAccuracyBest:
            return "Best"
            
        default:
            return ""
            
        }
    }
    
    var distanceAccuracy: Double {
        get {
            return defaults.doubleForKey(SettingsController.kLocationAccuracyKey)
        }
        set {
            defaults.setDouble(newValue, forKey: SettingsController.kLocationAccuracyKey)
            defaults.synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName(kSettingsControllerDidChangeNotification, object: nil)
        }
    }
    
    var locationTimeout: Int {
        get {
            return defaults.integerForKey(SettingsController.kLocationTimeoutKey)
        }
        set {
            defaults.setInteger(newValue, forKey: SettingsController.kLocationTimeoutKey)
            defaults.synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName(kSettingsControllerDidChangeNotification, object: nil)
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
    
    var unitStyle: Bool {
        get {
            return defaults.boolForKey(SettingsController.kUnitStyleKey)
        }
        set {
            defaults.setBool(newValue, forKey: SettingsController.kUnitStyleKey)
            defaults.synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName(kSettingsControllerDidChangeNotification, object: nil)
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
