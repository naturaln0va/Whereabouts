
import UIKit
import CoreData
import MapKit

class ListViewController: UITableViewController {

    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let moc = PersistentController.sharedController.moc
        
        let fetchRequest = DatabaseLocation.fetchRequest(moc, predicate: nil, sortedBy: "date", ascending: false)
        fetchRequest.fetchBatchSize = 24
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: "locations")
    }()
    
    private lazy var distanceFormatter: MKDistanceFormatter = {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .Abbreviated
        return formatter
    }()
    
    private lazy var assistant = LocationAssistant()
    private var currentLocaiton: CLLocation? {
        didSet {
            guard let indexPaths = tableView.indexPathsForVisibleRows, let currentLoc = currentLocaiton else { return }
            
            for indexPath in indexPaths {
                if let location = fetchedResultsController.objectAtIndexPath(indexPath) as? DatabaseLocation, let cell = tableView.cellForRowAtIndexPath(indexPath) as? LocationCell {
                    cell.setDistanceText(distanceFormatter.stringFromDistance(currentLoc.distanceFromLocation(location.location)))
                }
            }
        }
    }
    
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        assistant.delegate = self
        assistant.getLocation()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
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
            cell.configureCellWithLocation(Location(dbLocation: location))
            
            if let currentLoc = currentLocaiton {
                cell.setDistanceText(distanceFormatter.stringFromDistance(currentLoc.distanceFromLocation(location.location)))
            }
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let location = fetchedResultsController.objectAtIndexPath(indexPath) as? DatabaseLocation {
            let vc = DetailViewController(location: Location(dbLocation: location))
            
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                let nvc = StyledNavigationController(rootViewController: vc)
                
                nvc.modalPresentationStyle = .FormSheet
                
                presentViewController(nvc, animated: true, completion: nil)
            }
            else {
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if let location = self.fetchedResultsController.objectAtIndexPath(indexPath) as? DatabaseLocation {
            CloudController.sharedController.deleteLocationFromCloud(location) { success in
                if !success {
                    PersistentController.sharedController.saveLocation(Location(dbLocation: location))
                }
            }
            PersistentController.sharedController.deleteLocation(location)
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

extension ListViewController: LocationAssistantDelegate {
    
    func locationAssistantReceivedLocation(location: CLLocation, finished: Bool) {
        currentLocaiton = location
        assistant.terminate()
    }
    
}
