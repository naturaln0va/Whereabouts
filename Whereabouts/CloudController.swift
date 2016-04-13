
import UIKit
import CloudKit

class CloudController {
    
    static let sharedController = CloudController()
    static let kSyncCompleteNotificationKey = "syncComplete"
    static let kCloudErrorNotificationKey = "cloudError"
    
    private lazy var cloudSyncQueue = dispatch_queue_create("io.ackermann.whereabouts.cloud.sync", nil)
    private lazy var container = CKContainer.defaultContainer()
    private lazy var cloudLocations = [CloudLocation]()
    private lazy var fetchedNotificationIDs = [CKNotificationID]()
    
    private let DEBUG_CLOUD = true
    
    var syncing = false
        
    // MARK: - Public
    func sync() {
        syncing = true
        dispatch_async(cloudSyncQueue) { 
            self.getAuthentication { hasAuth, error in
                guard hasAuth else {
                    NSNotificationCenter.defaultCenter().postNotificationName(CloudController.kCloudErrorNotificationKey, object: error)
                    if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Error getting auth for the cloud: \(error?.localizedDescription)") }
                    self.syncing = false
                    return
                }
                
                self.getCloudLocations({ location in
                    PersistentController.sharedController.saveCloudLocation(location)
                    self.cloudLocations.append(location)
                }, completion: { error in
                    defer {
                        self.syncing = false
                    }
                    
                    if let e = error {
                        NSNotificationCenter.defaultCenter().postNotificationName(CloudController.kCloudErrorNotificationKey, object: e)
                        if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Error retrieving locations from the cloud: \(e.localizedDescription)") }
                    }
                    
                    for localLocation in PersistentController.sharedController.locations() {
                        if let _ = self.cloudLocations.indexOf({ $0.identifier == localLocation.identifier }) { continue }
                        
                        let semaphore = dispatch_semaphore_create(0)
                        self.saveLocalLocationToCloud(localLocation) { cloudLocation in
                            dispatch_semaphore_signal(semaphore)
                        }
                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                    }
                    
                    self.cloudLocations.removeAll()
                    NSNotificationCenter.defaultCenter().postNotificationName(CloudController.kSyncCompleteNotificationKey, object: nil)
                })
            }
        }
    }
    
    func subscribeToChanges() {
        dispatch_async(cloudSyncQueue) {
            self.getAuthentication { hasAuth, error in
                guard hasAuth else {
                    NSNotificationCenter.defaultCenter().postNotificationName(CloudController.kCloudErrorNotificationKey, object: error)
                    if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Error getting auth for the cloud: \(error?.localizedDescription)") }
                    return
                }
                
                self.container.privateCloudDatabase.fetchAllSubscriptionsWithCompletionHandler { subscriptions, error in
                    guard let subscriptions = subscriptions where error == nil else {
                        if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Failed fetching subscriptions with error: \(error?.localizedDescription)") }
                        return
                    }
                    
                    let subscriptionOptions: CKSubscriptionOptions = [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion]
                    
                    for subscription in subscriptions {
                        if subscription.recordType == "Location" && subscription.subscriptionOptions == subscriptionOptions {
                            if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: User is already subscribed.") }
                            SettingsController.sharedController.hasSubscribed = true
                            return
                        }
                    }
                    
                    let subscription = CKSubscription(recordType: CloudLocation.recordType, predicate: NSPredicate(value: true), options: subscriptionOptions)
                    
                    self.container.privateCloudDatabase.saveSubscription(subscription) { subscription, error in
                        if let sub = subscription where error == nil {
                            if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: User has subscribed. Subscription: \(sub)") }
                            SettingsController.sharedController.hasSubscribed = true
                        }
                        else {
                            if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: User failed to subscribe.") }
                        }
                    }
                }
            }
        }
    }
    
    func getChanges() {
        dispatch_async(cloudSyncQueue) {
            self.getAuthentication { hasAuth, error in
                guard hasAuth else {
                    NSNotificationCenter.defaultCenter().postNotificationName(CloudController.kCloudErrorNotificationKey, object: error)
                    if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Error getting auth for the cloud: \(error?.localizedDescription)") }
                    return
                }
                
                let fetchChangesOperation = CKFetchNotificationChangesOperation()
                fetchChangesOperation.allowsCellularAccess = true
                fetchChangesOperation.qualityOfService = .UserInitiated
                
                fetchChangesOperation.notificationChangedBlock = { notification in
                    if let queryNotification = notification as? CKQueryNotification where notification.notificationType == .Query {
                        self.handleNotification(queryNotification)
                        
                        if let notificationID = queryNotification.notificationID {
                            self.fetchedNotificationIDs.append(notificationID)
                        }
                    }
                }
                
                fetchChangesOperation.fetchNotificationChangesCompletionBlock = { token, error in
                    if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Finished fetching notifications with error: \(error?.localizedDescription).") }
                    
                    if self.fetchedNotificationIDs.count > 0 {
                        let markOperation = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: self.fetchedNotificationIDs)
                        markOperation.allowsCellularAccess = true
                        markOperation.qualityOfService = .Utility
                        
                        markOperation.markNotificationsReadCompletionBlock = { notificationIDs, error in
                            if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Marked notifications as read with error: \(error?.localizedDescription).") }
                            self.fetchedNotificationIDs.removeAll()
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                NSNotificationCenter.defaultCenter().postNotificationName(CloudController.kSyncCompleteNotificationKey, object: nil)
                            }
                        }
                        
                        self.container.addOperation(markOperation)
                    }
                }
                
                self.container.addOperation(fetchChangesOperation)
            }
        }
    }
    
    func saveLocalLocationToCloud(location: Location, completion: (CloudLocation? -> Void)?) {
        dispatch_async(cloudSyncQueue) {
            self.getAuthentication { hasAuth, error in
                guard hasAuth else {
                    NSNotificationCenter.defaultCenter().postNotificationName(CloudController.kCloudErrorNotificationKey, object: error)
                    if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Error getting auth for the cloud: \(error?.localizedDescription)") }
                    return
                }
                
                self.container.privateCloudDatabase.saveRecord(CloudLocation(localLocation: location).record) { record, error in
                    if let _ = record where error == nil {
                        if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Successfully saved location record") }
                    }
                    else {
                        if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Failed to save location record with error: \(error?.localizedDescription)") }
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
                    if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Error getting auth for the cloud: \(error?.localizedDescription)") }
                    return
                }
                
                self.container.privateCloudDatabase.deleteRecordWithID(recordID) { id, error in
                    if let e = error {
                        if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Failed to deleted location record with error: \(e.localizedDescription)") }
                        completion?(false)
                    }
                    else {
                        if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Successfully deleted location record") }
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
                    if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Error getting auth for the cloud: \(error?.localizedDescription)") }
                    return
                }
                
                let modifyOperation = CKModifyRecordsOperation(recordsToSave: [CloudLocation(dbLocation: location).record], recordIDsToDelete: nil)
                modifyOperation.savePolicy = .ChangedKeys
                modifyOperation.allowsCellularAccess = true
                modifyOperation.qualityOfService = .UserInitiated
                
                modifyOperation.modifyRecordsCompletionBlock = { records, recordIDs, error in
                    if let e = error {
                        if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Failed to update location record with error: \(e.localizedDescription)") }
                        completion?(false)
                    }
                    else {
                        if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Successfully updated location record") }
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
            if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: About to handle a 'Query' notification.") }
            handleNotification(CKQueryNotification(fromRemoteNotificationDictionary: info))
            completion(.NewData)
            
        case .ReadNotification:
            if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: About to handle a 'ReadNotification' notification.") }
            completion(.NoData)
            
        case .RecordZone:
            if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: About to handle a 'RecordZone' notification.") }
            completion(.NoData)
            
        }
    }
    
    // MARK: - Private
    private func getAuthentication(completion: ((Bool, NSError?) -> Void)) {
        container.accountStatusWithCompletionHandler {
            status, error in
            
            if error != nil {
                if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: An error occured getting auth. Error: \(error?.localizedDescription)") }
                completion(false, error)
            }
            
            completion(status == .Available, error)
        }
    }
    
    private func getCloudLocations(location: (CloudLocation -> Void), completion: (NSError? -> Void)) {
        let query = CKQuery(recordType: CloudLocation.recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: CloudLocation.CloudKeys.CreatedDate.rawValue, ascending: false)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.allowsCellularAccess = true
        queryOperation.qualityOfService = .UserInitiated
        
        queryOperation.queryCompletionBlock = { cursor, error in
            if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Completed cloud location fetch with error: \(error?.localizedDescription)") }
            dispatch_async(dispatch_get_main_queue()) { completion(error) }
        }
        
        queryOperation.recordFetchedBlock = { record in
            if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Recieved a location record.") }
            dispatch_async(dispatch_get_main_queue()) { location(CloudLocation(record: record)) }
        }
        
        container.privateCloudDatabase.addOperation(queryOperation)
    }
    
    private func getCloudLocationWithRecordID(recordID: CKRecordID, completion: (CloudLocation? -> Void)) {
        container.privateCloudDatabase.fetchRecordWithID(recordID) { record, error in
            if let record = record where error == nil {
                if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Recieved a location record with error: \(error?.localizedDescription)") }
                completion(CloudLocation(record: record))
            }
            else {
                if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Failed to recieve a location record with error: \(error?.localizedDescription)") }
                completion(nil)
            }
        }
    }
    
    private func handleNotification(notification: CKQueryNotification) {
        guard let recordID = notification.recordID else {
            if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: No record id in the notification. We can't do anything with that.") }
            return
        }
        
        switch notification.queryNotificationReason {
            
        case .RecordCreated:
            if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Recieved a record creation notification.") }
            getCloudLocationWithRecordID(recordID) { cloudLocation in
                if let location = cloudLocation {
                    PersistentController.sharedController.saveCloudLocation(location)
                }
            }
            
        case .RecordUpdated:
            if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Recieved a record update notification.") }
            getCloudLocationWithRecordID(recordID) { cloudLocation in
                if let location = cloudLocation {
                    PersistentController.sharedController.saveCloudLocation(location)
                }
            }
            
        case .RecordDeleted:
            if self.DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Recieved a record deletion notification.") }
            PersistentController.sharedController.deleteLocationWithCloudID(recordID)
        }
    }
    
}
