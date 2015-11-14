
import UIKit
import CoreData


class LocationsViewController: UIViewController
{
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let moc = PersistentController.sharedController.managedObjectContext
        
        let fetchRequest = Location.fetchRequest(moc, predicate: nil, sortedBy: "date", ascending: false)
        fetchRequest.fetchLimit = 100
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: "locations")
    }()
    
    private lazy var tableView: UITableView = {
        let tbl = UITableView(frame: CGRectZero, style: .Plain)
        
        tbl.delegate = self
        tbl.dataSource = self
        tbl.separatorStyle = .None
        tbl.backgroundColor = ColorController.backgroundColor
        tbl.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 64, right: 0)
        
        return tbl
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        title = "Whereabouts"
        view.backgroundColor = ColorController.backgroundColor
        
        let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "locateBarButtonWasPressed")
        let leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Settings-BarButton"), style: .Plain, target: self, action: "settingsBarButtonWasPressed")
        
        navigationItem.rightBarButtonItem = rightBarButtonItem
        navigationItem.leftBarButtonItem = leftBarButtonItem
        
        tableView.frame = view.frame
        tableView.registerNib(UINib(nibName: LocationCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: LocationCell.reuseIdentifier)
        
        view.addSubview(tableView)
        fetch()
    }
    
    // MARK: - BarButon Actions
    func locateBarButtonWasPressed()
    {
        presentViewController(RHANavigationViewController(rootViewController: NewLocationViewController()), animated: true, completion: nil)
    }
    
    func settingsBarButtonWasPressed()
    {
        
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
    
}


extension LocationsViewController: UITableViewDelegate, UITableViewDataSource
{
    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        return tableView.dequeueReusableCellWithIdentifier(LocationCell.reuseIdentifier, forIndexPath: indexPath)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
    {
//        if cell.tag == kLoadingCellTag {
//            performFetch(nil, cursor: fetchCursor)
//            return
//        }
        
        guard let cell = cell as? LocationCell else { fatalError("Expected to display a `RecipeCell`.") }
        if let location = fetchedResultsController.objectAtIndexPath(indexPath) as? Location {
            cell.location = location
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - UITableViewDataSource
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return LocationCell.cellHeight
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let section = fetchedResultsController.sections?[section]
        
        return section?.numberOfObjects ?? 0
    }
    
}
