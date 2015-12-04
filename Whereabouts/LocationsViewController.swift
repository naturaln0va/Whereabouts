
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
        let moc = PersistentController.sharedController.managedObjectContext
        
        let fetchRequest = Location.fetchRequest(moc, predicate: nil, sortedBy: "date", ascending: false)
        fetchRequest.fetchBatchSize = 20
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: "locations")
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
        
        let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "locateBarButtonWasPressed")
        let leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Settings-BarButton"), style: .Plain, target: self, action: "settingsBarButtonWasPressed")
        
        navigationItem.rightBarButtonItem = rightBarButtonItem
        navigationItem.leftBarButtonItem = leftBarButtonItem
        
        tableView.separatorStyle = .None
        tableView.backgroundColor = ColorController.backgroundColor
        tableView.registerNib(UINib(nibName: LocationCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: LocationCell.reuseIdentifier)
        
        fetchedResultsController.delegate = self
        fetch()
        
        searchController.searchBar.sizeToFit()
        tableView.tableHeaderView = searchController.searchBar
        searchController.delegate = self
        
        searchController.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        searchController.searchBar.delegate = self
        searchController.searchBar.autocapitalizationType = .Sentences
        searchController.searchBar.searchBarStyle = .Minimal
        searchController.searchBar.backgroundColor = ColorController.backgroundColor
        searchController.searchBar.tintColor = ColorController.navBarBackgroundColor
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
    
    // MARK: - Private
    private func fetch()
    {
        do {
            try fetchedResultsController.performFetch()
        }
        
        catch {
            print("Error fetching for the results controller: \(error)")
        }
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        return tableView.dequeueReusableCellWithIdentifier(LocationCell.reuseIdentifier, forIndexPath: indexPath)
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
    {
        guard let cell = cell as? LocationCell else { fatalError("Expected to display a `LocationCell`.") }
        
        if filteredLocations != nil {
            cell.location = filteredLocations![indexPath.row]
        }
        else if let location = fetchedResultsController.objectAtIndexPath(indexPath) as? Location {
            cell.location = location
        }
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
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]?
    {
        let shareAction = UITableViewRowAction(style: .Default, title: "Share") { action, indexPath in
            if let location = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Location {
                let firstActivityItem = location.shareableString()
                let activityViewController : UIActivityViewController = UIActivityViewController(
                    activityItems: [firstActivityItem], applicationActivities: nil)
                
                activityViewController.excludedActivityTypes = [
                    UIActivityTypePrint,
                    UIActivityTypeAssignToContact,
                    UIActivityTypeSaveToCameraRoll,
                    UIActivityTypeAddToReadingList,
                    UIActivityTypePostToFlickr,
                    UIActivityTypePostToVimeo
                ]
                
                self.presentViewController(activityViewController, animated: true, completion: nil)
            }
        }
        shareAction.backgroundColor = UIColor(hex: 0x1e76a0)
        
        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete") { action, indexPath in
            if let location = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Location {
                PersistentController.sharedController.deleteLocation(location)
            }
        }
        deleteAction.backgroundColor = UIColor.alizarinColor()
        
        return filteredLocations == nil ? [deleteAction, shareAction] : nil
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle
    {
        if #available(iOS 9.0, *) {
            return .None
        }
        else {
            return .Delete
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if #available(iOS 9.0, *) {
            return
        }
        else {
            if let location = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Location {
                PersistentController.sharedController.deleteLocation(location)
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return LocationCell.cellHeight
    }
    
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
                    cell.location = location
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
