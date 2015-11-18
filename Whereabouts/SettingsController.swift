
import Foundation

let kSettingsControllerDidChangeLocationAccuracy: String = "settingsControllerDidChangeLocationAccuracy"
let kSettingsControllerDidChangeLocationTimeout: String = "settingsControllerDidChangeLocationTimeout"
let kSettingsControllerDidChangeNearbyPhotoRange: String = "settingsControllerDidChangeNearbyPhotoRange"
let kSettingsControllerDidChangeUnitStyle: String = "settingsControllerDidChangeUnitStyle"


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
            kLocationTimeoutKey: 20,
            kNearbyPhotoRangeKey: 150,
            kUnitStyleKey: false
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
    var distanceAccuracy: Double {
        get {
            return defaults.doubleForKey(SettingsController.kLocationAccuracyKey)
        }
        set {
            defaults.setDouble(newValue, forKey: SettingsController.kLocationAccuracyKey)
            defaults.synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName(kSettingsControllerDidChangeLocationAccuracy, object: nil)
        }
    }
    
    var locationTimeout: Int {
        get {
            return defaults.integerForKey(SettingsController.kLocationTimeoutKey)
        }
        set {
            defaults.setInteger(newValue, forKey: SettingsController.kLocationTimeoutKey)
            defaults.synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName(kSettingsControllerDidChangeLocationTimeout, object: nil)
        }
    }
    
    var nearbyPhotoRange: Int {
        get {
            return defaults.integerForKey(SettingsController.kNearbyPhotoRangeKey)
        }
        set {
            defaults.setInteger(newValue, forKey: SettingsController.kNearbyPhotoRangeKey)
            defaults.synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName(kSettingsControllerDidChangeNearbyPhotoRange, object: nil)
        }
    }
    
    var unitStyle: Bool {
        get {
            return defaults.boolForKey(SettingsController.kUnitStyleKey)
        }
        set {
            defaults.setBool(newValue, forKey: SettingsController.kUnitStyleKey)
            defaults.synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName(kSettingsControllerDidChangeUnitStyle, object: nil)
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
