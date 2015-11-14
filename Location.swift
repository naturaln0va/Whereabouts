
import Foundation
import CoreData


class Location: NSManagedObject
{

}


extension Location: Fetchable
{
    
    typealias FetchableType = Location
    
    static func entityName() -> String
    {
        return "Location"
    }
    
}
