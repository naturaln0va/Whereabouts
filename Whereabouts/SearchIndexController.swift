
import Foundation
import CoreSpotlight

class SearchIndexController {
    
    static let sharedController = SearchIndexController()
    static let DEBUG_SEARCH = true
    
    var canUseCoreSpotlight: Bool {
        return CSSearchableIndex.isIndexingAvailable()
    }
    
    func indexLocations() {
        guard canUseCoreSpotlight else { return }
        
        let locations = PersistentController.sharedController.locations()
        
        let items = locations.map { location in
            return CSSearchableItem(
                uniqueIdentifier: location.identifier,
                domainIdentifier: location.placemark?.locality,
                attributeSet: location.searchableAttributes
            )
        }
        
        CSSearchableIndex.defaultSearchableIndex().indexSearchableItems(items) { error in
            if SearchIndexController.DEBUG_SEARCH {
                if let e = error {
                    print("***SEARCHINDEXCONTROLLER: Failed to index locations: \(e)")
                }
                else {
                    print("***SEARCHINDEXCONTROLLER: Indexed \(items.count) locations.")
                }
            }
        }
    }
    
    func indexLocation(location: Location) {
        guard canUseCoreSpotlight else { return }
        
        let item = CSSearchableItem(
            uniqueIdentifier: location.identifier,
            domainIdentifier: location.placemark?.locality,
            attributeSet: location.searchableAttributes
        )
        
        CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([item]) { error in
            if SearchIndexController.DEBUG_SEARCH {
                if let e = error {
                    print("***SEARCHINDEXCONTROLLER: Failed to index location with identifier: \(location.identifier). Error: \(e)")
                }
                else {
                    print("***SEARCHINDEXCONTROLLER: Indexed location with identifier \(location.identifier).")
                }
            }
        }
    }
    
    func removeLocationFromIndex(location: Location) {
        guard canUseCoreSpotlight else { return }
        
         CSSearchableIndex.defaultSearchableIndex().deleteSearchableItemsWithIdentifiers([location.identifier]) { error in
            if SearchIndexController.DEBUG_SEARCH {
                if let e = error {
                    print("***SEARCHINDEXCONTROLLER: Failed to remove location with identifier: \(location.identifier) from the index: \(e)")
                }
                else {
                    print("***SEARCHINDEXCONTROLLER: Removed location with identifier \(location.identifier) from the index.")
                }
            }
        }
    }
    
}