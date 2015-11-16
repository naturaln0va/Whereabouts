
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
            
            try coordinator.addPersistentStoreWithType(
                NSSQLiteStoreType,
                configuration: nil,
                URL: storeURL,
                options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
            )
            
            let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            return context
        } catch {
            fatalError("Error adding persistent store at \(storeURL): \(error)")
        }
    }()
    
    func deleteLocation(locationToDelete: Location)
    {
        managedObjectContext.deleteObject(locationToDelete)
        
        managedObjectContext.performBlockAndWait { [unowned self] in
            do {
                try self.managedObjectContext.save()
            }
                
            catch {
                fatalError("Error deleting location: \(error)")
            }
        }
    }
    
    func updateLocation(locationToUpdate: Location, title: String, color: UIColor?)
    {
        do {
            if let result = try Location.singleObjectInContext(managedObjectContext, predicate: NSPredicate(format: "identifier == [c] %@", locationToUpdate.identifier), sortedBy: nil, ascending: false) {
                result.locationTitle = title
                result.color = color
                
                
                managedObjectContext.performBlockAndWait { [unowned self] in
                    do {
                        try self.managedObjectContext.save()
                    }
                        
                    catch {
                        fatalError("Error saving location: \(error)")
                    }
                }
            }
            else {
                print("Error there was no entity with that identifier.")
            }
        }
            
        catch {
            print("Error adding or updating location: \(locationToUpdate.title) ・ \(locationToUpdate.date)")
        }
    }
    
    func saveLocation(title: String, color: UIColor?, placemark: CLPlacemark?, location: CLLocation)
    {
        guard let dataToSave = NSEntityDescription.insertNewObjectForEntityForName(Location.entityName(), inManagedObjectContext: managedObjectContext) as? Location else {
            fatalError("Expected to insert and entity of type 'Location'.")
        }
        
        dataToSave.date = location.timestamp
        dataToSave.locationTitle = title
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