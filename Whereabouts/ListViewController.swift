
import UIKit
import CoreData
import MapKit

class ListViewController: UITableViewController {

    enum FilterScope: String {
        case All
        case Recent
        case Nearby
        
        static func scopeForIndex(index: Int) -> FilterScope {
            switch index {
                
            case 0:
                return .All
                
            case 1:
                return .Recent
                
            case 2:
                return .Nearby
                
            default:
                return .All
            }
        }
    }
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let moc = PersistentController.sharedController.moc
        
        let fetchRequest = DatabaseLocation.fetchRequest(moc, predicate: nil, sortedBy: "date", ascending: false)
        fetchRequest.fetchBatchSize = 24
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: "locations")
    }()
    
    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.hidesNavigationBarDuringPresentation = false
        sc.dimsBackgroundDuringPresentation = false
        
        sc.searchBar.delegate = self
        sc.searchBar.searchBarStyle = .Prominent
        sc.searchBar.scopeButtonTitles = ["All", "Recent"]
        sc.searchBar.layer.borderWidth = 1
        sc.searchBar.layer.borderColor = StyleController.sharedController.backgroundColor.CGColor
        sc.searchBar.barTintColor = StyleController.sharedController.backgroundColor
        sc.searchBar.tintColor = StyleController.sharedController.mainTintColor
        return sc
    }()
    
    private lazy var distanceFormatter: MKDistanceFormatter = {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .Abbreviated
        return formatter
    }()
    
    private lazy var visits = [Visit]()
    private lazy var filteredLocations = [Location]()
    
    private lazy var assistant = LocationAssistant()
    private var currentLocaiton: CLLocation? {
        didSet {
            guard let indexPaths = tableView.indexPathsForVisibleRows, let currentLoc = currentLocaiton else { return }
            
            searchController.searchBar.scopeButtonTitles = ["All", "Recent", "Nearby"]
            
            for indexPath in indexPaths {
                if let location = fetchedResultsController.objectAtIndexPath(indexPath) as? DatabaseLocation, let cell = tableView.cellForRowAtIndexPath(indexPath) as? LocationCell {
                    cell.setDistanceText(distanceFormatter.stringFromDistance(currentLoc.distanceFromLocation(location.location)))
                }
            }
        }
    }
    
    private var shouldDisplayFilteredLocations: Bool {
        guard searchController.active else { return false }
        
        if filteredLocations.count > 0 && searchController.searchBar.selectedScopeButtonIndex != 0 {
            return true
        }
        else if searchController.searchBar.text?.characters.count > 0 && searchController.searchBar.selectedScopeButtonIndex == 0 {
            return true
        }
        else {
            return false
        }
    }
    
    deinit {
        fetchedResultsController.delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        definesPresentationContext = true
        
        tableView = UITableView(frame: CGRect.zero, style: .Grouped)
        tableView.keyboardDismissMode = .OnDrag
        tableView.backgroundColor = view.backgroundColor
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = LocationCell.cellHeight
        tableView.registerNib(UINib(nibName: LocationCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: LocationCell.reuseIdentifier)
        
        if PersistentController.sharedController.locations().count < 6 {
            tableView.contentOffset.y = searchController.searchBar.bounds.height
        }
        
        searchController.searchResultsUpdater = self
        tableView.tableHeaderView = searchController.searchBar
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(ListViewController.visitsChanged),
            name: PersistentController.PersistentControllerVistsDidUpdate,
            object: nil
        )
        
        fetchedResultsController.delegate = self
        fetchLocations()
        
        if SettingsController.sharedController.shouldMonitorVisits {
            visits = PersistentController.sharedController.visits()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        assistant.delegate = self
        assistant.getLocation()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        searchController.searchBar.endEditing(true)
        searchController.active = false
        
        assistant.terminate()
    }

    private func fetchLocations() {
        do {
            try fetchedResultsController.performFetch()
        }
            
        catch {
            print("Error fetching for the results controller: \(error)")
        }
    }
    
    // MARK: - Notifications
    @objc private func visitsChanged() {
        visits = PersistentController.sharedController.visits()
        tableView.reloadData()
    }
    
    // MARK: - Helpers
    func filterContentForSearchText(searchText: String, filterScope: FilterScope) {
        guard let databaseLocations = fetchedResultsController.fetchedObjects as? [DatabaseLocation] else {
            return
        }
        
        let locations = databaseLocations.map { return Location(dbLocation: $0) }
        let searchString = searchText.lowercaseString
        
        let preFilteredLocations = locations.filter { location in
            var titleString = ""
            var subtitleString = ""
            var contentString = ""
            
            if let title = location.title {
                titleString = title.lowercaseString
            }
            else if let subtitle = location.subtitle {
                subtitleString = subtitle.lowercaseString
            }
            else if let content = location.textContent {
                contentString = content.lowercaseString
            }
            
            return titleString.containsString(searchString) || subtitleString.containsString(searchString) || contentString.containsString(searchString)
        }
        
        switch filterScope {
            
        case .All:
            filteredLocations = preFilteredLocations
            
        case .Recent:
            let locationsToFilter = preFilteredLocations.count == 0 ? locations : preFilteredLocations
            filteredLocations = locationsToFilter.filter { location in
                return NSDate().daysSince(location.date) < 2
            }
            
        case .Nearby:
            guard let currentLocaiton = currentLocaiton else { return }
            
            let locationsToFilter = preFilteredLocations.count == 0 ? locations : preFilteredLocations
            filteredLocations = locationsToFilter.filter { location in
                return currentLocaiton.distanceFromLocation(location.location) < 1000
            }
            
        }
        
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 && visits.count > 0 {
            return 12.0
        }
        
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 && visits.count > 0 {
            let cell = UITableViewCell(style: .Value1, reuseIdentifier: "defaultCell")
            
            cell.textLabel?.text = "This week's visited locations"
            cell.detailTextLabel?.text = String(visits.count)
            cell.accessoryType = .DisclosureIndicator
            
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCellWithIdentifier(LocationCell.reuseIdentifier) as? LocationCell else {
            fatalError("Expected to dequeue a 'LocationCell'.")
        }
        
        var locationToConfigure: Location
        
        if shouldDisplayFilteredLocations {
            locationToConfigure = filteredLocations[indexPath.row]
        }
        else if let location = fetchedResultsController.objectAtIndexPath(indexPath) as? DatabaseLocation {
            locationToConfigure = Location(dbLocation: location)
        }
        else {
            fatalError("ERROR: Failed to parse a location to display.")
        }
        
        cell.configureCellWithLocation(locationToConfigure)
        
        if let currentLoc = currentLocaiton {
            cell.setDistanceText(distanceFormatter.stringFromDistance(currentLoc.distanceFromLocation(locationToConfigure.location)))
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 0 && visits.count > 0 {
            let vc = VisitsViewController(visits: visits, location: currentLocaiton)
            navigationController?.pushViewController(vc, animated: true)
        }
        
        var locationToConfigure: Location
        
        if shouldDisplayFilteredLocations {
            locationToConfigure = filteredLocations[indexPath.row]
        }
        else if let location = fetchedResultsController.objectAtIndexPath(indexPath) as? DatabaseLocation {
            locationToConfigure = Location(dbLocation: location)
        }
        else {
            fatalError("ERROR: Failed to parse a location to display.")
        }

        let vc = DetailViewController(location: locationToConfigure)
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            let nvc = StyledNavigationController(rootViewController: vc)
            
            nvc.modalPresentationStyle = .FormSheet
            
            presentViewController(nvc, animated: true, completion: nil)
        }
        else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if (indexPath.section == 0 && visits.count > 0) || searchController.active {
            return .None
        }
        return .Delete
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && visits.count > 0 {
            return
        }
        
        if let location = fetchedResultsController.objectAtIndexPath(indexPath) as? DatabaseLocation {
            CloudController.sharedController.deleteLocationFromCloudWithIdentifier(location.identifier) { success in
                if !success {
                    PersistentController.sharedController.saveLocation(Location(dbLocation: location))
                }
            }
            PersistentController.sharedController.deleteLocation(location)
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 && visits.count > 0 {
            return 44.0
        }
        
        return UITableViewAutomaticDimension
    }
    
    // MARK: - UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return visits.count > 0 ? 2 : 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && visits.count > 0 {
            return 1
        }
        
        if shouldDisplayFilteredLocations {
            return filteredLocations.count
        }
        else {
            let section = fetchedResultsController.sections?[section]
            
            return section?.numberOfObjects ?? 0
        }
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension ListViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            
        case .Update:
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? LocationCell {
                if let location = fetchedResultsController.objectAtIndexPath(indexPath!) as? DatabaseLocation {
                    cell.configureCellWithLocation(Location(dbLocation: location))
                    
                    if let currentLoc = currentLocaiton {
                        cell.setDistanceText(distanceFormatter.stringFromDistance(currentLoc.distanceFromLocation(location.location)))
                    }
                }
            }
            
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
}

// MARK: - LocationAssistantDelegate
extension ListViewController: LocationAssistantDelegate {
    
    func locationAssistantReceivedLocation(location: CLLocation, finished: Bool) {
        currentLocaiton = location
        assistant.terminate()
    }
    
}

// MARK: - UISearchResultsUpdating
extension ListViewController: UISearchResultsUpdating {
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let scope = FilterScope.scopeForIndex(searchController.searchBar.selectedScopeButtonIndex)
        filterContentForSearchText(searchController.searchBar.text ?? "", filterScope: scope)
    }
    
}

extension ListViewController: UISearchBarDelegate {
    
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        let scope = FilterScope.scopeForIndex(selectedScope)
        filterContentForSearchText(searchController.searchBar.text ?? "", filterScope: scope)
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        tableView.scrollIndicatorInsets.top = searchBar.frame.height
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        tableView.scrollIndicatorInsets.top = searchBar.frame.height
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        tableView.scrollIndicatorInsets.top = searchBar.frame.height
    }
    
}
