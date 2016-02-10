
import UIKit
import CoreData


class LocationsViewController: UITableViewController
{
    
    private let searchController = UISearchController(searchResultsController: nil)
    private var filteredLocations: Array<Location>? {
        didSet {
            tableView.reloadData()
        }
    }
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let moc = PersistentController.sharedController.locationMOC
        
        let fetchRequest = Location.fetchRequest(moc, predicate: nil, sortedBy: "date", ascending: false)
        fetchRequest.fetchBatchSize = 20
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: "locations")
    }()
    
    private lazy var spaceBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
    }()
    
    
    deinit
    {
        fetchedResultsController.delegate = nil
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        title = "Whereabouts"
        view.backgroundColor = ColorController.backgroundColor

        navigationController?.toolbarHidden = false
        
        let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "locateBarButtonWasPressed")
        let leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Settings-BarButton"), style: .Plain, target: self, action: "settingsBarButtonWasPressed")
        
        navigationItem.rightBarButtonItem = rightBarButtonItem
        navigationItem.leftBarButtonItem = leftBarButtonItem
        
        tableView.separatorStyle = .None
        tableView.backgroundColor = ColorController.backgroundColor
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = LocationCell.cellHeight
        tableView.registerNib(UINib(nibName: LocationCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: LocationCell.reuseIdentifier)
        
        fetchedResultsController.delegate = self
        fetchLocations()
        
        searchController.searchBar.sizeToFit()
        tableView.tableHeaderView = searchController.searchBar
        searchController.delegate = self
        
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        searchController.searchBar.delegate = self
        searchController.searchBar.autocapitalizationType = .Sentences
        searchController.searchBar.searchBarStyle = .Minimal
        searchController.searchBar.backgroundColor = ColorController.backgroundColor
        searchController.searchBar.tintColor = ColorController.navBarBackgroundColor
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        refreshVisits()
    }
    
    // MARK: - BarButon Actions
    func locateBarButtonWasPressed()
    {
        let newlocationVC = NewLocationViewController()
        newlocationVC.assistant = LocationAssistant(viewController: newlocationVC)
        presentViewController(StyledNavigationController(rootViewController: newlocationVC), animated: true, completion: nil)
    }
    
    func settingsBarButtonWasPressed()
    {
        presentViewController(StyledNavigationController(rootViewController: SettingsViewController()), animated: true, completion: nil)
    }
    
    func visitsBarButtonPressed()
    {
        presentViewController(StyledNavigationController(rootViewController: VisitsMapViewController()), animated: true, completion: nil)
    }
    
    // MARK: - Private
    private func fetchLocations()
    {
        do {
            try fetchedResultsController.performFetch()
        }
        
        catch {
            print("Error fetching for the results controller: \(error)")
        }
    }
    
    private func refreshVisits()
    {
        guard SettingsController.sharedController.shouldMonitorVisits else {
            toolbarItems = nil
            navigationController?.toolbarHidden = true
            return
        }
        
        let numberOfVisits = Visit.objectCountInContext(PersistentController.sharedController.visitMOC)
        if numberOfVisits > 0 {
            navigationController?.toolbarHidden = false
            
            let visitItem = UIBarButtonItem(title: "\(numberOfVisits) Visits", style: .Plain, target: self, action: "visitsBarButtonPressed")
            
            toolbarItems = [spaceBarButtonItem, visitItem, spaceBarButtonItem]
        }
        else {
            toolbarItems = nil
            navigationController?.toolbarHidden = true
        }
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCellWithIdentifier(LocationCell.reuseIdentifier) as? LocationCell else {
            fatalError("Expected to dequeue a 'LocationCell'.")
        }

        if filteredLocations != nil {
            cell.configureCell(filteredLocations![indexPath.row])
        }
        else if let location = fetchedResultsController.objectAtIndexPath(indexPath) as? Location {
            cell.configureCell(location)
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        searchController.searchBar.resignFirstResponder()
        
        if filteredLocations != nil {
            let detailVC = LocationDetailViewController()
            detailVC.locationToDisplay = filteredLocations![indexPath.row]
            navigationController?.pushViewController(detailVC, animated: true)
        }
        else if let location = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Location {
            let detailVC = LocationDetailViewController()
            detailVC.locationToDisplay = location
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle
    {
        if filteredLocations == nil {
            return .Delete
        }
        else {
            return .None
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if let location = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Location {
            PersistentController.sharedController.deleteLocation(location)
        }
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if filteredLocations != nil {
            return filteredLocations!.count
        }
        
        let section = fetchedResultsController.sections?[section]
        
        return section?.numberOfObjects ?? 0
    }
    
}


extension LocationsViewController: NSFetchedResultsControllerDelegate
{
    
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            
        case .Update:
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? LocationCell {
                if let location = fetchedResultsController.objectAtIndexPath(indexPath!) as? Location {
                    cell.configureCell(location)
                }
            }
            
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        tableView.endUpdates()
    }
    
}


extension LocationsViewController: UISearchBarDelegate, UISearchControllerDelegate
{
    
    // MARK: UISearchBarDelegate
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool
    {
        return true
    }
    
    func searchBarShouldEndEditing(searchBar: UISearchBar) -> Bool
    {
        return true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar)
    {
        filteredLocations = nil
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String)
    {
        if let fetched: NSArray = fetchedResultsController.fetchedObjects, let searchText = searchBar.text {
            if searchText.characters.count == 0 {
                filteredLocations = nil
                return
            }
            
            let filteredFetch = fetched.filteredArrayUsingPredicate(NSPredicate(format: "locationTitle CONTAINS[c] %@", searchText))
            filteredLocations = filteredFetch.map { obj in
                return obj as! Location
            }
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar)
    {
        searchBar.resignFirstResponder()
    }

}
