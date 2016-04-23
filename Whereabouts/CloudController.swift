
import UIKit
import CloudKit

let DEBUG_CLOUD = false

class CloudController {
    
    static let sharedController = CloudController()
    static let kSyncDidStartNotificationKey = "syncStarted"
    static let kSyncCompleteNotificationKey = "syncComplete"
    static let kCloudErrorNotificationKey = "cloudError"
    
    private lazy var cloudSyncQueue = dispatch_queue_create("io.ackermann.whereabouts.cloud.sync", nil)
    private lazy var container = CKContainer.defaultContainer()
    
    private lazy var mainQueue = NSOperationQueue.mainQueue()
    
    var syncing = false
        
    // MARK: - Public
    func sync() {
        syncing = true
        NSNotificationCenter.defaultCenter().postNotificationName(CloudController.kSyncDidStartNotificationKey, object: nil)
        dispatch_async(cloudSyncQueue) { [weak self] in
            self?.getAuthentication { hasAuth, error in
                guard hasAuth else {
                    NSNotificationCenter.defaultCenter().postNotificationName(CloudController.kCloudErrorNotificationKey, object: error)
                    if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Error getting auth for the cloud: \(error?.localizedDescription)") }
                    self?.syncing = false
                    return
                }
                
                guard let container = self?.container else {
                    NSNotificationCenter.defaultCenter().postNotificationName(CloudController.kCloudErrorNotificationKey, object: nil)
                    return
                }
                
                let fetchNotificationOperation = NotificationFetchOperation(container: container)
                let markNotificationOperation = NotificationMarkOperation(container: container)
                let syncOperation = CloudSyncOperation(container: container)
                
                syncOperation.completionBlock = {
                    self?.syncing = false
                    if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Cloud sync complete.") }
                    SettingsController.sharedController.lastCloudSync = NSDate()
                    dispatch_async(dispatch_get_main_queue()) { NSNotificationCenter.defaultCenter().postNotificationName(CloudController.kSyncCompleteNotificationKey, object: nil) }
                }
                
                fetchNotificationOperation |> markNotificationOperation
                markNotificationOperation |> syncOperation
                
                self?.mainQueue.maxConcurrentOperationCount = 1
                self?.mainQueue.qualityOfService = .UserInitiated
                self?.mainQueue.addOperations([fetchNotificationOperation, markNotificationOperation, syncOperation], waitUntilFinished: false)
            }
        }
    }
    
    func subscribeToChanges() {
        dispatch_async(cloudSyncQueue) {
            self.getAuthentication { hasAuth, error in
                guard hasAuth else {
                    NSNotificationCenter.defaultCenter().postNotificationName(CloudController.kCloudErrorNotificationKey, object: error)
                    if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Error getting auth for the cloud: \(error?.localizedDescription)") }
                    return
                }
                
                self.container.privateCloudDatabase.fetchAllSubscriptionsWithCompletionHandler { subscriptions, error in
                    guard let subscriptions = subscriptions where error == nil else {
                        if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Failed fetching subscriptions with error: \(error?.localizedDescription)") }
                        return
                    }
                    
                    let subscriptionOptions: CKSubscriptionOptions = [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion]
                    
                    for subscription in subscriptions {
                        if subscription.recordType == "Location" && subscription.subscriptionOptions == subscriptionOptions {
                            if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: User is already subscribed.") }
                            SettingsController.sharedController.hasSubscribed = true
                            return
                        }
                    }
                    
                    let subscription = CKSubscription(recordType: CloudLocation.recordType, predicate: NSPredicate(value: true), options: subscriptionOptions)
                    
                    self.container.privateCloudDatabase.saveSubscription(subscription) { subscription, error in
                        if let sub = subscription where error == nil {
                            if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: User has subscribed. Subscription: \(sub)") }
                            SettingsController.sharedController.hasSubscribed = true
                        }
                        else {
                            if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: User failed to subscribe.") }
                        }
                    }
                }
            }
        }
    }
    
    func saveLocalLocationToCloud(location: Location, completion: (CloudLocation? -> Void)?) {
        dispatch_async(cloudSyncQueue) {
            self.getAuthentication { hasAuth, error in
                guard hasAuth else {
                    NSNotificationCenter.defaultCenter().postNotificationName(CloudController.kCloudErrorNotificationKey, object: error)
                    if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Error getting auth for the cloud: \(error?.localizedDescription)") }
                    return
                }
                
                self.container.privateCloudDatabase.saveRecord(CloudLocation(localLocation: location).record) { record, error in
                    if let _ = record where error == nil {
                        if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Successfully saved location record") }
                    }
                    else {
                        if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Failed to save location record with error: \(error?.localizedDescription)") }
                    }
                    
                    if let cloudRecord = record {
                        completion?(CloudLocation(record: cloudRecord))
                    }
                    else {
                        completion?(nil)
                    }
                }
            }
        }
    }
    
    func deleteLocationFromCloud(location: DatabaseLocation, completion: (Bool -> Void)?) {
        guard let data = location.cloudRecordIdentifierData, let recordID = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? CKRecordID else {
            print("Failed to parse location's record id. Data: \(location.cloudRecordIdentifierData)")
            completion?(false)
            return
        }
        
        dispatch_async(cloudSyncQueue) {
            self.getAuthentication { hasAuth, error in
                guard hasAuth else {
                    NSNotificationCenter.defaultCenter().postNotificationName(CloudController.kCloudErrorNotificationKey, object: error)
                    if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Error getting auth for the cloud: \(error?.localizedDescription)") }
                    return
                }
                
                self.container.privateCloudDatabase.deleteRecordWithID(recordID) { id, error in
                    if let e = error {
                        if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Failed to deleted location record with error: \(e.localizedDescription)") }
                        completion?(false)
                    }
                    else {
                        if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Successfully deleted location record") }
                        completion?(true)
                    }
                }
            }
        }
    }
    
    func updateLocationOnCloud(location: DatabaseLocation, completion: (Bool -> Void)?) {
        guard let data = location.cloudRecordIdentifierData, let _ = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? CKRecordID else {
            print("Failed to parse location's record id. Data: \(location.cloudRecordIdentifierData)")
            completion?(false)
            return
        }
        
        dispatch_async(cloudSyncQueue) {
            self.getAuthentication { hasAuth, error in
                guard hasAuth else {
                    NSNotificationCenter.defaultCenter().postNotificationName(CloudController.kCloudErrorNotificationKey, object: error)
                    if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Error getting auth for the cloud: \(error?.localizedDescription)") }
                    return
                }
                
                let modifyOperation = CKModifyRecordsOperation(recordsToSave: [CloudLocation(dbLocation: location).record], recordIDsToDelete: nil)
                modifyOperation.savePolicy = .ChangedKeys
                modifyOperation.allowsCellularAccess = true
                modifyOperation.qualityOfService = .UserInitiated
                
                modifyOperation.modifyRecordsCompletionBlock = { records, recordIDs, error in
                    if let e = error {
                        if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Failed to update location record with error: \(e.localizedDescription)") }
                        completion?(false)
                    }
                    else {
                        if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Successfully updated location record") }
                        completion?(true)
                    }
                }
                
                self.container.privateCloudDatabase.addOperation(modifyOperation)
            }
        }
    }
    
    func handleNotificationInfo(notificationInfo: [NSObject : AnyObject], completion: (UIBackgroundFetchResult -> Void)) {
        guard let info = notificationInfo as? [String: NSObject] else {
            completion(.Failed)
            return
        }
        
        let notification = CKNotification(fromRemoteNotificationDictionary: info)
        
        switch notification.notificationType {
        case .Query:
            if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: About to handle a 'Query' notification.") }
            handleNotification(CKQueryNotification(fromRemoteNotificationDictionary: info))
            completion(.NewData)
            
        case .ReadNotification:
            if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: About to handle a 'ReadNotification' notification.") }
            completion(.NoData)
            
        case .RecordZone:
            if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: About to handle a 'RecordZone' notification.") }
            completion(.NoData)
            
        }
    }
    
    func handleNotification(notification: CKQueryNotification) {
        guard let recordID = notification.recordID else {
            if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: No record id in the notification. We can't do anything with that.") }
            return
        }
        
        switch notification.queryNotificationReason {
            
        case .RecordCreated:
            if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Recieved a record creation notification.") }
            getCloudLocationWithRecordID(recordID) { cloudLocation in
                if let location = cloudLocation {
                    PersistentController.sharedController.saveCloudLocation(location)
                }
            }
            
        case .RecordUpdated:
            if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Recieved a record update notification.") }
            getCloudLocationWithRecordID(recordID) { cloudLocation in
                if let location = cloudLocation {
                    PersistentController.sharedController.saveCloudLocation(location)
                }
            }
            
        case .RecordDeleted:
            if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Recieved a record deletion notification.") }
            PersistentController.sharedController.deleteLocationWithCloudID(recordID)
        }
    }
    
    // MARK: - Private
    private func getAuthentication(completion: ((Bool, NSError?) -> Void)) {
        container.accountStatusWithCompletionHandler {
            status, error in
            
            if error != nil {
                if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: An error occured getting auth. Error: \(error?.localizedDescription)") }
                completion(false, error)
            }
            
            completion(status == .Available, error)
        }
    }
    
    private func getCloudLocationWithRecordID(recordID: CKRecordID, completion: (CloudLocation? -> Void)) {
        container.privateCloudDatabase.fetchRecordWithID(recordID) { record, error in
            if let record = record where error == nil {
                if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Recieved a location record with error: \(error?.localizedDescription)") }
                completion(CloudLocation(record: record))
            }
            else {
                if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Failed to recieve a location record with error: \(error?.localizedDescription)") }
                completion(nil)
            }
        }
    }
    
}
