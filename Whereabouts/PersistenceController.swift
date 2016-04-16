
import UIKit
import CoreData
import CoreLocation
import CloudKit

class PersistentController {
    
    static let sharedController = PersistentController()
    private let kMigratedLegacyDataKey: String = "migratedLegacyData"
    
    private let DEBUG_DATABASE = true
    
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
    lazy var moc: NSManagedObjectContext = {
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
                if DEBUG_DATABASE { debugPrint("***PERSISTENTCONTROLLER: Found \(fetched.count) legacy objects: \(fetched)") }
            }
            else {
                if DEBUG_DATABASE { debugPrint("***PERSISTENTCONTROLLER: No legacy data to transfer.") }
            }
            
            for legacyLocation in fetched {
                if let placemark = legacyLocation.valueForKey("placemark") as? CLPlacemark where placemark.location != nil {
                    
                    let location = Location(location: placemark.location!)
                    location.placemark = placemark
                    saveLocation(location)
                }
                else {
                    if DEBUG_DATABASE { debugPrint("***PERSISTENTCONTROLLER: Did not find a placemark in: \(legacyLocation), or the location was nil.") }
                }
            }
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: kMigratedLegacyDataKey)
        }
            
        catch {
            if DEBUG_DATABASE { debugPrint("***PERSISTENTCONTROLLER: Could not get old objects") }
        }
    }
    
    // MARK: - Location Management
    func locations() -> [Location] {
        if let locations = try? DatabaseLocation.objectsInContext(moc) {
            return locations.map { dbLocation in
                return Location(dbLocation: dbLocation)
            }
        }
        return []
    }
    
    func saveLocation(location: Location) {
        if let dbLocation = locationForIdentifier(location.identifier) {
            updateDatabaseLocationWithLocation(dbLocation, location: location)
            
            if dbLocation.cloudRecordIdentifierData != nil {
                CloudController.sharedController.updateLocationOnCloud(dbLocation, completion: nil)
            }
            return
        }
        else {
            // save location to cloud
            CloudController.sharedController.saveLocalLocationToCloud(location) { cloudLocation in
                if let location = cloudLocation, let recordID = location.recordID {
                    self.updateDatabaseLocationWithID(location.identifier, cloudID: recordID)
                }
            }
        }
        
        guard let dataToSave = NSEntityDescription.insertNewObjectForEntityForName(DatabaseLocation.entityName(), inManagedObjectContext: moc) as? DatabaseLocation else {
            fatalError("Expected to insert and entity of type 'DatabaseLocation'.")
        }
        
        if DEBUG_DATABASE { debugPrint("***PERSISTENTCONTROLLER: Saving location: \(location).") }

        dataToSave.date = location.date
        dataToSave.textContent = location.textContent
        dataToSave.locationTitle = location.locationTitle
        dataToSave.placemark = location.placemark
        dataToSave.location = location.location
        dataToSave.identifier = location.identifier
        dataToSave.itemName = location.mapItem?.name
        dataToSave.itemPhoneNumber = location.mapItem?.phoneNumber
        dataToSave.itemWebLink = location.mapItem?.url?.absoluteString
        
        if moc.hasChanges {
            moc.performBlockAndWait { [unowned self] in
                do {
                    try self.moc.save()
                }
                    
                catch {
                    fatalError("Error saving location: \(error)")
                }
            }
        }
    }
    
    func saveCloudLocation(location: CloudLocation) {
        if let dbLocation = locationForIdentifier(location.identifier) {
            updateDatabaseLocationWithLocation(dbLocation, location: Location(cloudLocation: location), cloudID: location.recordID)
            return
        }
        
        guard let dataToSave = NSEntityDescription.insertNewObjectForEntityForName(DatabaseLocation.entityName(), inManagedObjectContext: moc) as? DatabaseLocation else {
            fatalError("Expected to insert and entity of type 'DatabaseLocation'.")
        }
        
        dataToSave.date = location.createdDate
        dataToSave.locationTitle = location.locationTitle
        dataToSave.textContent = location.textContent
        dataToSave.placemark = location.place
        dataToSave.location = location.location
        dataToSave.identifier = location.identifier
        dataToSave.itemName = location.itemName
        dataToSave.itemPhoneNumber = location.itemPhoneNumber
        dataToSave.itemWebLink = location.itemWebLink
        
        if let recordID = location.recordID {
            dataToSave.cloudRecordIdentifierData = NSKeyedArchiver.archivedDataWithRootObject(recordID)
        }
        
        if moc.hasChanges {
            moc.performBlockAndWait { [unowned self] in
                do {
                    try self.moc.save()
                }
                    
                catch {
                    fatalError("Error saving location: \(error)")
                }
            }
        }
    }
    
    func deleteLocation(locationToDelete: DatabaseLocation) {
        moc.deleteObject(locationToDelete)
        
        if DEBUG_DATABASE { debugPrint("***PERSISTENTCONTROLLER: Deleting database location: \(locationToDelete).") }
        
        if moc.hasChanges {
            moc.performBlockAndWait { [unowned self] in
                do {
                    try self.moc.save()
                }
                    
                catch {
                    fatalError("Error deleting location: \(error)")
                }
            }
        }
    }
    
    func deleteLocationWithCloudID(cloudID: CKRecordID) {
        guard let locations = try? DatabaseLocation.objectsInContext(moc) else {
            if DEBUG_DATABASE { debugPrint("***PERSISTENTCONTROLLER: No locations in the database.") }
            return
        }
        
        if let locationIndexToDelete = locations.indexOf({ location in
            if let data = location.cloudRecordIdentifierData, let recordID = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? CKRecordID where recordID == cloudID {
                return true
            }
            return false
        }) {
            deleteLocation(locations[locationIndexToDelete])
        }
        else {
            if DEBUG_DATABASE { debugPrint("***PERSISTENTCONTROLLER: Was not able to find a location to delete.") }
        }
    }
    
    private func updateDatabaseLocationWithID(identifier: String, cloudID: CKRecordID) {
        guard let locationToUpdate = locationForIdentifier(identifier) else {
            return
        }
        
        locationToUpdate.cloudRecordIdentifierData = NSKeyedArchiver.archivedDataWithRootObject(cloudID)
        if DEBUG_DATABASE { debugPrint("***PERSISTENTCONTROLLER: Updated local location with cloud id.") }
        
        if moc.hasChanges {
            moc.performBlockAndWait { [unowned self] in
                do {
                    try self.moc.save()
                }
                    
                catch {
                    fatalError("Error saving location: \(error)")
                }
            }
        }
    }
    
    private func updateDatabaseLocationWithLocation(dbLocation: DatabaseLocation, location: Location) {
        updateDatabaseLocationWithLocation(dbLocation, location: location, cloudID: nil)
    }
    
    private func updateDatabaseLocationWithLocation(dbLocation: DatabaseLocation, location: Location, cloudID: CKRecordID?) {
        if DEBUG_DATABASE { debugPrint("***PERSISTENTCONTROLLER: Updating location: \(location).") }
        
        dbLocation.date = location.date
        dbLocation.locationTitle = location.locationTitle
        dbLocation.textContent = location.textContent
        dbLocation.placemark = location.placemark
        dbLocation.location = location.location
        dbLocation.identifier = location.identifier
        dbLocation.itemName = location.mapItem?.name
        dbLocation.itemPhoneNumber = location.mapItem?.phoneNumber
        dbLocation.itemWebLink = location.mapItem?.url?.absoluteString
        
        if let recordID = cloudID {
            dbLocation.cloudRecordIdentifierData = NSKeyedArchiver.archivedDataWithRootObject(recordID)
        }
        
        if moc.hasChanges {
            moc.performBlockAndWait { [unowned self] in
                do {
                    try self.moc.save()
                }
                    
                catch {
                    fatalError("Error deleting location: \(error)")
                }
            }
        }
    }
    
    private func locationForIdentifier(identifier: String) -> DatabaseLocation? {
        if let location = try? DatabaseLocation.singleObjectInContext(moc, predicate: NSPredicate(format: "identifier == [c] %@", identifier), sortedBy: nil, ascending: false) {
            return location
        }
        else {
            return nil
        }
    }
    
    // MARK: - Visit Management
    func visits() -> [Visit] {
        if let visits = try? DatabaseVisit.objectsInContext(moc) {
            return visits.map { dbVisit in
                return Visit(dbVisit: dbVisit)
            }
        }
        return []
    }
    
    func cleanUpVisits() {
        if let visits = try? DatabaseVisit.objectsInContext(moc) {
            var visitsToDelete = [DatabaseVisit]()
            for visit in visits {
                if visit.arrivalDate.isMoreThanAWeekOld() || visit.departureDate.isMoreThanAWeekOld() {
                    visitsToDelete.append(visit)
                }
            }
            deleteVisits(visitsToDelete)
        }
    }
    
    func deleteVisit(visitToDelete: DatabaseVisit) {
        moc.deleteObject(visitToDelete)
        
        if moc.hasChanges {
            moc.performBlockAndWait { [unowned self] in
                do {
                    try self.moc.save()
                }
                    
                catch {
                    fatalError("Error deleting visit: \(error)")
                }
            }
        }
    }
    
    func deleteVisits(visitsToDelete: [DatabaseVisit]) {
        for visit in visitsToDelete {
            moc.deleteObject(visit)
        }
        
        if moc.hasChanges {
            do {
                try self.moc.save()
            }
                
            catch {
                fatalError("Error deleting visit: \(error)")
            }
        }
    }
    
    func saveVisit(visitToSave: Visit) {
        guard let dataToSave = NSEntityDescription.insertNewObjectForEntityForName(DatabaseVisit.entityName(), inManagedObjectContext: moc) as? DatabaseVisit else {
            fatalError("Expected to insert and entity of type 'Visit'.")
        }
        
        dataToSave.identifier = visitToSave.identifier
        dataToSave.totalVisits = visitToSave.totalVisits
        dataToSave.arrivalDate = visitToSave.arrivalDate
        dataToSave.departureDate = visitToSave.departureDate
        dataToSave.horizontalAccuracy = visitToSave.horizontalAccuracy
        dataToSave.coordinate = visitToSave.coordinate
        dataToSave.address = visitToSave.address
        
        if moc.hasChanges {
            moc.performBlockAndWait { [unowned self] in
                do {
                    try self.moc.save()
                }
                    
                catch {
                    fatalError("Error saving visit: \(error)")
                }
            }
        }
    }
    
    func visitWasVisited(visit: Visit) {
        if let result = try? DatabaseVisit.singleObjectInContext(moc, predicate: NSPredicate(format: "identifier == [c] %@", visit.identifier), sortedBy: nil, ascending: false) {
            
            if let visitToUpdate = result {
                visitToUpdate.totalVisits = visitToUpdate.totalVisits + 1
                
                if moc.hasChanges {
                    moc.performBlockAndWait { [unowned self] in
                        do {
                            try self.moc.save()
                        }
                            
                        catch {
                            fatalError("Error saving location: \(error)")
                        }
                    }
                }
            }
            else {
                if DEBUG_DATABASE { debugPrint("***PERSISTENTCONTROLLER: Error updating visit with identifier: \(visit.identifier)") }
            }
        }
        else {
            if DEBUG_DATABASE { debugPrint("***PERSISTENTCONTROLLER: Error failed to get visit with identifier: \(visit.identifier).") }
        }
    }
    
}
