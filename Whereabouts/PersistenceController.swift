
import UIKit
import CoreData
import CoreLocation


class PersistentController
{
    
    static let sharedController = PersistentController()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        guard let modelURL = NSBundle.mainBundle().URLForResource("DataModel", withExtension: "momd") else {
            fatalError("Could not find the data model in the bundle")
        }
        
        guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("error initializing model from: \(modelURL)")
        }
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentsDirectory = urls[0]
        let storeURL = documentsDirectory.URLByAppendingPathComponent("DataStore.sqlite")
        
        do {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
            
            let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            return context
        } catch {
            fatalError("Error adding persistent store at \(storeURL): \(error)")
        }
    }()
    
    func saveLocation(title: String, color: UIColor?, placemark: CLPlacemark?, location: CLLocation)
    {
        guard let dataToSave = NSEntityDescription.insertNewObjectForEntityForName(Location.entityName(), inManagedObjectContext: managedObjectContext) as? Location else {
            fatalError("Expected to insert and entity of type 'Location'.")
        }
        
        dataToSave.date = location.timestamp
        dataToSave.title = title
        dataToSave.color = color
        dataToSave.placemark = placemark
        dataToSave.location = location
        dataToSave.identifier = "\(location.timestamp.timeIntervalSince1970)+\(title)+\(location.coordinate.longitude)+\(location.coordinate.latitude)"
        
        managedObjectContext.performBlockAndWait { [unowned self] in
            do {
                try self.managedObjectContext.save()
            }
                
            catch {
                fatalError("Error saving location: \(error)")
            }
        }
    }
    
}