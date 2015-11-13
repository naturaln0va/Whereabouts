
import CoreData


class PersistenceController : NSObject
{
    static let sharedController = PersistenceController()
    
    private(set) var managedObjectContext: NSManagedObjectContext?
    private var privateContext: NSManagedObjectContext?
    
    private lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    func save()
    {
        if let pc = privateContext, let moc = managedObjectContext {
            if !pc.hasChanges && !moc.hasChanges {
                return
            }
            
            moc.performBlockAndWait {
                do {
                    try moc.save()
                } catch let error as NSError {
                    print("Error when saving publicly to CoreData: \(error)")
                }
                
                pc.performBlockAndWait {
                    do {
                        try pc.save()
                    } catch let error as NSError {
                        print("Error when saving privatly to CoreData: \(error)")
                    }
                }
            }
        }
        
    }
    
    func initializeCoreData()
    {
        if let _ = managedObjectContext {
            return
        }
        
        let modelURL = NSBundle.mainBundle().URLForResource("DataModel", withExtension: "momd")
        if let url = modelURL, let mom = NSManagedObjectModel(contentsOfURL: url) {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: mom)
            
            managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            
            if let pc = privateContext, moc = managedObjectContext {
                pc.persistentStoreCoordinator = coordinator
                moc.parentContext = pc
            }
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            if let pc = self.privateContext, let psc = pc.persistentStoreCoordinator {
                
                var options = [NSObject: AnyObject]()
                options[NSMigratePersistentStoresAutomaticallyOption] = true
                options[NSInferMappingModelAutomaticallyOption] = true
                options[NSSQLitePragmasOption] = ["journal_mode": "DELETE"]

                let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("DataModel.sqlite")
                
                do {
                    try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options)
                } catch let error as NSError {
                    print("Error when initializing CoreData: \(error)")
                }
            }
        }
    }
}
