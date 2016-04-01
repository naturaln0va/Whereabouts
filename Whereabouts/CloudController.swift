
import Foundation
import CloudKit

class CloudController {
    
    static let sharedController = CloudController()
    static let kSyncCompleteNotificationKey = "syncComplete"
    static let kCloudErrorNotificationKey = "cloudError"
    
    private lazy var cloudSyncQueue = dispatch_queue_create("io.ackermann.whereabouts.cloud.sync", nil)
    private lazy var container = CKContainer.defaultContainer()
    private lazy var cloudLocations = [CloudLocation]()
        
    // MARK: - Public
    func sync() {
        dispatch_async(cloudSyncQueue) { 
            self.getAuthentication { hasAuth, error in
                guard hasAuth else {
                    NSNotificationCenter.defaultCenter().postNotificationName(CloudController.kCloudErrorNotificationKey, object: error)
                    return
                }
                
                self.getCloudLocations({ location in
                    PersistentController.sharedController.saveCloudLocationIfNeeded(location)
                    self.cloudLocations.append(location)
                }, completion: { error in
                    if let e = error {
                        NSNotificationCenter.defaultCenter().postNotificationName(CloudController.kCloudErrorNotificationKey, object: e)
                        print("Error retrieving locations from the cloud: \(e)")
                    }
                    
                    for localLocation in PersistentController.sharedController.locations() {
                        if let _ = self.cloudLocations.indexOf({ $0.identifier == localLocation.identifier }) { continue }
                        
                        let semaphore = dispatch_semaphore_create(0)
                        self.saveLocalLocationToCloud(localLocation) {
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
    
    func saveLocalLocationToCloud(location: Location, completion: (Void -> Void)?) {
        container.privateCloudDatabase.saveRecord(CloudLocation(localLocation: location).record) { record, error in
            if let savedRecord = record where error == nil {
                print("Saved \(savedRecord) to the cloud.")
            }
            else {
                print("Error saving to the cloud: \(error)")
            }
            completion?()
        }
    }
    
    func deleteLocationFromCloud(location: DatabaseLocation, completion: (Void -> Void)?) {
        let query = CKQuery(recordType: CloudLocation.recordType, predicate: NSPredicate(format: "%K == %@", CloudLocation.CloudKeys.Identifier.rawValue, location.identifier))
        
        container.privateCloudDatabase.performQuery(query, inZoneWithID: nil) { records, error in
            if let recordToDelete = records?.first {
                self.container.privateCloudDatabase.deleteRecordWithID(recordToDelete.recordID) { deletedRecordID, error in
                    if let deletedRecordID = deletedRecordID where error == nil {
                        print("Deleted record with id: \(deletedRecordID)")
                    }
                    else if let error = error {
                        print("Error deleting record with id: \(deletedRecordID) error: \(error)")
                    }
                    completion?()
                }
            }
            else if let error = error {
                print("Error retrieving record: \(error)")
            }
        }
    }
    
    // MARK: - Private
    private func getAuthentication(completion: ((Bool, NSError?) -> Void)) {
        container.accountStatusWithCompletionHandler {
            status, error in
            
            if error != nil {
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
            dispatch_async(dispatch_get_main_queue()) { completion(error) }
        }
        
        queryOperation.recordFetchedBlock = { record in
            dispatch_async(dispatch_get_main_queue()) { location(CloudLocation(record: record)) }
        }
        
        container.privateCloudDatabase.addOperation(queryOperation)
    }
    
}
