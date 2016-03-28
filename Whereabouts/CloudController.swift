
import Foundation
import CloudKit

class CloudController {
    
    static let SharedController = CloudController()
    
    private lazy var container = CKContainer.defaultContainer()
    private lazy var locationModelRecordName = "Location"
    
    private enum CloudKeys: String {
        case CreatedDate = "createdDate"
        case Color = "color"
        case Identifier = "identifier"
        case Location = "location"
        case Title = "locationTitle"
        case MapItem = "mapItem"
        case Place = "place"
    }
    
    // MARK: - Public
    func sync() {
        getAuthentication { hasAuth in
            guard hasAuth else {
                return
            }
            
            self.getCloudLocations() { location in
                
            }
            
            // compare local data with retrieved data
            
            // if new data
            // save locations that do not exist on device
            
            // if we have data that the cloud doesn't we need to save
        }
    }
    
    // MARK: - Private
    private func getAuthentication(completion: (Bool -> Void)) {
        container.accountStatusWithCompletionHandler {
            status, error in
            
            if error != nil {
                completion(false)
            }
            
            completion(status == .Available)
        }
    }
    
    private func getCloudLocations(completion: (CKRecord -> Void)) {
        let query = CKQuery(recordType: locationModelRecordName, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: CloudKeys.CreatedDate.rawValue, ascending: false)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.allowsCellularAccess = true
        queryOperation.qualityOfService = .UserInitiated
        
        queryOperation.recordFetchedBlock = { record in
            dispatch_async(dispatch_get_main_queue()) { completion(record) }
        }
        
        container.privateCloudDatabase.addOperation(queryOperation)
    }
    
}
