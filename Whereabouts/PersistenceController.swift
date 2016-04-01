
import UIKit
import CoreData
import CoreLocation


class PersistentController {
    
    static let sharedController = PersistentController()
    private let kMigratedLegacyDataKey: String = "migratedLegacyData"
    
    //MARK: - Legacy Model
    lazy var legacyManagedObjectContext: NSManagedObjectContext = {
        guard let modelURL = NSBundle.mainBundle().URLForResource("DataModel", withExtension: "momd") else {
            fatalError("Could not find the data model in the bundle")
        }
        
        guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("error initializing model from: \(modelURL)")
        }
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentsDirectory = urls[0]
        let storeURL = documentsDirectory.URLByAppendingPathComponent("asd.sqlite")

        do {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            
            try coordinator.addPersistentStoreWithType(
                NSSQLiteStoreType,
                configuration: nil,
                URL: storeURL,
                options: nil
            )
            
            let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            return context
        }
            
        catch {
            fatalError("Error adding persistent store at \(storeURL): \(error)")
        }
    }()
    
    // MARK: - Current Models
    lazy var locationMOC: NSManagedObjectContext = {
        guard let modelURL = NSBundle.mainBundle().URLForResource("LocationModel", withExtension: "momd") else {
            fatalError("Could not find the data model in the bundle")
        }
        
        guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("error initializing model from: \(modelURL)")
        }
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentsDirectory = urls[0]
        let storeURL = documentsDirectory.URLByAppendingPathComponent("LocationModel.sqlite")
        
        do {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
                configuration: nil,
                URL: storeURL,
                options: [
                    NSMigratePersistentStoresAutomaticallyOption: true,
                    NSInferMappingModelAutomaticallyOption: true
                ]
            )
            
            let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            return context
        }
        
        catch {
            fatalError("Error adding persistent store at \(storeURL): \(error)")
        }
    }()
    
    lazy var visitMOC: NSManagedObjectContext = {
        guard let modelURL = NSBundle.mainBundle().URLForResource("VisitModel", withExtension: "momd") else {
            fatalError("Could not find the data model in the bundle")
        }
        
        guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("error initializing model from: \(modelURL)")
        }
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentsDirectory = urls[0]
        let storeURL = documentsDirectory.URLByAppendingPathComponent("VisitModel.sqlite")
        
        do {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
                configuration: nil,
                URL: storeURL,
                options: [
                    NSMigratePersistentStoresAutomaticallyOption: true,
                    NSInferMappingModelAutomaticallyOption: true
                ]
            )
            
            let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            return context
        }
            
        catch {
            fatalError("Error adding persistent store at \(storeURL): \(error)")
        }
    }()
    
    // MARK: - Core Data Helpers
    func migrateLegacyData() {
        if NSUserDefaults.standardUserDefaults().boolForKey(kMigratedLegacyDataKey) == true {
            return
        }
        
        let request = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: legacyManagedObjectContext)
        request.entity = entity
        
        do {
            let fetched = try legacyManagedObjectContext.executeFetchRequest(request) as! [NSManagedObject]
            if fetched.count > 0 {
                print("Found \(fetched.count) legacy objects: \(fetched)")
            }
            else {
                print("No legacy data to transfer.")
            }
            
            for legacyLocation in fetched {
                if let placemark = legacyLocation.valueForKey("placemark") as? CLPlacemark where placemark.location != nil {
                    let formatter = NSDateFormatter()
                    formatter.dateStyle = .ShortStyle
                    
                    var titleForLocation = formatter.stringFromDate(placemark.location!.timestamp)
                    if let state = placemark.administrativeArea {
                        titleForLocation += ", \(state)"
                    }
                    
                    //saveLocation(titleForLocation, color: nil, placemark: placemark, location: placemark.location!)
                }
                else {
                    print("Did not find a placemark in: \(legacyLocation), or the location was nil.")
                }
            }
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: kMigratedLegacyDataKey)
        }
            
        catch {
            print("Could not get old objects")
        }
    }
    
    // MARK: - Location Management
    func locations() -> [Location] {
        if let locations = try? DatabaseLocation.objectsInContext(locationMOC) {
            return locations.map { dbLocation in
                return Location(dbLocation: dbLocation)
            }
        }
        return []
    }
    
    func saveCloudLocationIfNeeded(location: CloudLocation) {
        guard locationForIdentifier(location.identifier) == nil else {
            return
        }
        
        guard let dataToSave = NSEntityDescription.insertNewObjectForEntityForName(DatabaseLocation.entityName(), inManagedObjectContext: locationMOC) as? DatabaseLocation else {
            fatalError("Expected to insert and entity of type 'Location'.")
        }
        
        dataToSave.date = location.createdDate
        dataToSave.textContent = location.textContent
        dataToSave.color = location.color.characters.count > 0 ? UIColor(rgba: location.color) : nil
        dataToSave.placemark = location.place
        dataToSave.location = location.location
        dataToSave.identifier = location.identifier
        dataToSave.itemName = location.itemName
        dataToSave.itemPhoneNumber = location.itemPhoneNumber
        dataToSave.itemWebLink = location.itemWebLink
        
        if locationMOC.hasChanges {
            locationMOC.performBlockAndWait { [unowned self] in
                do {
                    try self.locationMOC.save()
                }
                    
                catch {
                    fatalError("Error saving location: \(error)")
                }
            }
        }
    }
    
    func locationForIdentifier(identifier: String) -> DatabaseLocation? {
        if let location = try? DatabaseLocation.singleObjectInContext(locationMOC, predicate: NSPredicate(format: "identifier == [c] %@", identifier), sortedBy: nil, ascending: false) {
            return location
        }
        else {
            return nil
        }
    }
    
    func deleteLocation(locationToDelete: DatabaseLocation) {
        locationMOC.deleteObject(locationToDelete)
        
        if locationMOC.hasChanges {
            locationMOC.performBlockAndWait { [unowned self] in
                do {
                    try self.locationMOC.save()
                }
                    
                catch {
                    fatalError("Error deleting location: \(error)")
                }
            }
        }
    }
    
    func updateDatabaseLocationWithID(identifier: String, location: Location) {
        // TODO
    }
    
    func saveLocation(location: Location) {
        guard let dataToSave = NSEntityDescription.insertNewObjectForEntityForName(DatabaseLocation.entityName(), inManagedObjectContext: locationMOC) as? DatabaseLocation else {
            fatalError("Expected to insert and entity of type 'Location'.")
        }
        
        dataToSave.date = location.date
        dataToSave.textContent = location.textContent
        dataToSave.color = location.color
        dataToSave.placemark = location.placemark
        dataToSave.location = location.location
        dataToSave.identifier = location.identifier
        dataToSave.itemName = location.mapItem?.name
        dataToSave.itemPhoneNumber = location.mapItem?.phoneNumber
        dataToSave.itemWebLink = String(location.mapItem?.url)
        
        if locationMOC.hasChanges {
            locationMOC.performBlockAndWait { [unowned self] in
                do {
                    try self.locationMOC.save()
                }
                    
                catch {
                    fatalError("Error saving location: \(error)")
                }
            }
        }
    }
    
    // MARK: - Visits Management
    func cleanUpVisits() {
        if let allVisits = try? Visit.objectsInContext(visitMOC) {
            var visitsToDelete = [Visit]()
            for visit in allVisits {
                if visit.arrivalDate.isMoreThanAWeekOld() || visit.departureDate.isMoreThanAWeekOld() {
                    visitsToDelete.append(visit)
                }
            }
            deleteVisits(visitsToDelete)
        }
    }
    
    func deleteVisit(visitToDelete: Visit) {
        visitMOC.deleteObject(visitToDelete)
        
        if visitMOC.hasChanges {
            visitMOC.performBlockAndWait { [unowned self] in
                do {
                    try self.visitMOC.save()
                }
                    
                catch {
                    fatalError("Error deleting visit: \(error)")
                }
            }
        }
    }
    
    func deleteVisits(visitsToDelete: [Visit]) {
        for visit in visitsToDelete {
            visitMOC.deleteObject(visit)
        }
        
        if visitMOC.hasChanges {
            do {
                try self.visitMOC.save()
            }
                
            catch {
                fatalError("Error deleting visit: \(error)")
            }
        }
    }
    
    func saveVisit(arrivalDate: NSDate, departureDate: NSDate, horizontalAccuracy: CLLocationAccuracy, coordinate: CLLocationCoordinate2D, address: CLPlacemark?) {
        cleanUpVisits()
        
        guard let dataToSave = NSEntityDescription.insertNewObjectForEntityForName(Visit.entityName(), inManagedObjectContext: visitMOC) as? Visit else {
            fatalError("Expected to insert and entity of type 'Visit'.")
        }
        
        dataToSave.identifier = NSUUID().UUIDString
        dataToSave.totalVisits = 1
        dataToSave.arrivalDate = arrivalDate
        dataToSave.departureDate = departureDate
        dataToSave.horizontalAccuracy = horizontalAccuracy
        dataToSave.coordinate = coordinate
        dataToSave.address = address
        
        if visitMOC.hasChanges {
            visitMOC.performBlockAndWait { [unowned self] in
                do {
                    try self.visitMOC.save()
                }
                    
                catch {
                    fatalError("Error saving visit: \(error)")
                }
            }
        }
    }
    
    func visitWasVisited(visit: Visit) {
        if let result = try? Visit.singleObjectInContext(visitMOC, predicate: NSPredicate(format: "identifier == [c] %@", visit.identifier), sortedBy: nil, ascending: false) {
            
            if let visitToUpdate = result {
                visitToUpdate.totalVisits = visitToUpdate.totalVisits + 1
                
                if visitMOC.hasChanges {
                    visitMOC.performBlockAndWait { [unowned self] in
                        do {
                            try self.visitMOC.save()
                        }
                            
                        catch {
                            fatalError("Error saving location: \(error)")
                        }
                    }
                }
            }
            else {
                print("Error adding or updating location: \(visit.identifier)")
            }
        }
        else {
            print("Error there was no entity with that identifier.")
        }
    }
    
}
