
import CloudKit

class NotificationMarkOperation: ConcurrentOperation {
    
    private let container: CKContainer
    
    init(container: CKContainer) {
        self.container = container
    }
    
    override func start() {
        guard let notificationProvider = dependencies.filter({ $0 is NotificationIDProvider }).first as? NotificationIDProvider else {
            cancel()
            return
        }
        
        if notificationProvider.notificationIDs.count > 0 {
            let markOperation = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: notificationProvider.notificationIDs)
            markOperation.allowsCellularAccess = true
            markOperation.qualityOfService = .Utility
            
            markOperation.markNotificationsReadCompletionBlock = { notificationIDs, error in
                if DEBUG_CLOUD { debugPrint("***CLOUDCONTROLLER: Marked notifications as read with error: \(error?.localizedDescription).") }
                self.state = .Finished
            }
            
            container.addOperation(markOperation)
        }
        else {
            self.state = .Finished
        }
    }
    
}