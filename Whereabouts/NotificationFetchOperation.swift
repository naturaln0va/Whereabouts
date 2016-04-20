
import CloudKit

protocol NotificationIDProvider {
    var notificationIDs: [CKNotificationID] { get }
}

class NotificationFetchOperation: ConcurrentOperation {
    
    private let container: CKContainer
    private var fetchedNotificationIDs = [CKNotificationID]()
    
    init(container: CKContainer) {
        self.container = container
    }
    
    override func start() {
        let fetchChangesOperation = CKFetchNotificationChangesOperation()
        fetchChangesOperation.allowsCellularAccess = true
        fetchChangesOperation.qualityOfService = .UserInitiated
        
        fetchChangesOperation.notificationChangedBlock = { [weak self] notification in
            if let queryNotification = notification as? CKQueryNotification where notification.notificationType == .Query {
                CloudController.sharedController.handleNotification(queryNotification)
                
                if let notificationID = queryNotification.notificationID {
                    self?.fetchedNotificationIDs.append(notificationID)
                }
            }
        }
        
        fetchChangesOperation.fetchNotificationChangesCompletionBlock = { [weak self] token, error in
            if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Finished fetching notifications with error: \(error?.localizedDescription).") }
            
            self?.state = .Finished
        }
        
        container.addOperation(fetchChangesOperation)
    }
    
}

extension NotificationFetchOperation: NotificationIDProvider {
    
    var notificationIDs: [CKNotificationID] { return fetchedNotificationIDs }
    
}
