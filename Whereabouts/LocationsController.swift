
import UIKit
import CoreData
import CoreLocation


class LocationsController: NSObject
{
    var locations: [Location]?
    
    static let sharedController = LocationsController()
    
    var count: Int
    {
        if let locs = locations {
            return locs.count
        }
        return 0
    }
    
    override init()
    {
        super.init()
        
        if let moc = PersistenceController.sharedController.managedObjectContext {
            
            let fetchRequest = NSFetchRequest()
            fetchRequest.entity = NSEntityDescription.entityForName(Location.kLocationEntityNameKey, inManagedObjectContext: moc)
            
            let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            do {
                let fetchResults = try moc.executeFetchRequest(fetchRequest) as? [Location]
                locations = fetchResults
            } catch let error as NSError {
                print("Error fetching locations from CoreData: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - CoreData
    
    func saveLocation(title title: String?, latitude: Double, longitude: Double, placemark: CLPlacemark?, date: NSDate, color: UIColor?)
    {
        if let moc = PersistenceController.sharedController.managedObjectContext {
            let location = NSEntityDescription.insertNewObjectForEntityForName(Location.kLocationEntityNameKey, inManagedObjectContext: moc) as! Location
            
            location.title = title
            location.latitude = latitude
            location.longitude = longitude
            location.placemark = placemark
            location.date = date
            location.color = color
            
            do {
                try moc.save()
                print("Save Successful!")
                if let _ = locations {
                    locations!.append(location)
                }
            } catch let error as NSError {
                print("Could not save \(error), \(error.userInfo)")
            }
        }
    }
    
}
