
import UIKit
import CoreData

class ListViewController: UITableViewController {

    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let moc = PersistentController.sharedController.locationMOC
        
        let fetchRequest = DatabaseLocation.fetchRequest(moc, predicate: nil, sortedBy: "date", ascending: false)
        fetchRequest.fetchBatchSize = 24
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: "locations")
    }()
    
    deinit {
        fetchedResultsController.delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView = UITableView(frame: CGRect.zero, style: .Grouped)
        tableView.backgroundColor = view.backgroundColor
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = LocationCell.cellHeight
        tableView.registerNib(UINib(nibName: LocationCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: LocationCell.reuseIdentifier)
        
        fetchedResultsController.delegate = self
        fetchLocations()
    }

    private func fetchLocations() {
        do {
            try fetchedResultsController.performFetch()
        }
            
        catch {
            print("Error fetching for the results controller: \(error)")
        }
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier(LocationCell.reuseIdentifier) as? LocationCell else {
            fatalError("Expected to dequeue a 'LocationCell'.")
        }
        
        if let location = fetchedResultsController.objectAtIndexPath(indexPath) as? DatabaseLocation {
            cell.configureCell(Location(dbLocation: location))
        }
        
        return cell
    }
    
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let cell = tableView.dequeueReusableCellWithIdentifier(LocationCell.reuseIdentifier) as? LocationCell else {
            fatalError("Expected to dequeue a 'LocationCell'.")
        }
        
        if let location = fetchedResultsController.objectAtIndexPath(indexPath) as? DatabaseLocation {
            cell.configureCell(Location(dbLocation: location))
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let location = fetchedResultsController.objectAtIndexPath(indexPath) as? DatabaseLocation {
            let detailVC = LocationDetailViewController()
            detailVC.locationToDisplay = Location(dbLocation: location)
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if let location = self.fetchedResultsController.objectAtIndexPath(indexPath) as? DatabaseLocation {
            CloudController.sharedController.deleteLocationFromCloud(location) { success in
                PersistentController.sharedController.deleteLocation(location)
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = fetchedResultsController.sections?[section]
        
        return section?.numberOfObjects ?? 0
    }
    
}

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
                    cell.configureCell(Location(dbLocation: location))
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
