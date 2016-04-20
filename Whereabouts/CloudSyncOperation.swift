
import CloudKit

class CloudSyncOperation: ConcurrentOperation {
    
    private let container: CKContainer
    private lazy var cloudLocations = [CloudLocation]()
    
    init(container: CKContainer) {
        self.container = container
    }
    
    override func start() {
        let query = CKQuery(recordType: CloudLocation.recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: CloudLocation.CloudKeys.CreatedDate.rawValue, ascending: false)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.allowsCellularAccess = true
        queryOperation.qualityOfService = .UserInitiated
        
        queryOperation.recordFetchedBlock = { [weak self] record in
            if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Recieved a location record.") }
            let location = CloudLocation(record: record)
            PersistentController.sharedController.saveCloudLocation(location)
            self?.cloudLocations.append(location)
        }
        
        queryOperation.queryCompletionBlock = { [weak self] cursor, error in
            if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Completed cloud location fetch with error: \(error?.localizedDescription)") }
            
            if let e = error {
                NSNotificationCenter.defaultCenter().postNotificationName(CloudController.kCloudErrorNotificationKey, object: e)
                if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Error retrieving locations from the cloud: \(e.localizedDescription)") }
                self?.cancel()
                return
            }
            
            for localLocation in PersistentController.sharedController.locations() {
                if let _ = self?.cloudLocations.indexOf({ $0.identifier == localLocation.identifier }) { continue }
                
                let semaphore = dispatch_semaphore_create(0)
                CloudController.sharedController.saveLocalLocationToCloud(localLocation) { _ in
                    dispatch_semaphore_signal(semaphore)
                }
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            }
            
            self?.cloudLocations.removeAll()
            
            self?.state = .Finished
        }
        
        container.privateCloudDatabase.addOperation(queryOperation)
    }
    
}
