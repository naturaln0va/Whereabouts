
import UIKit
import MapKit

class VisitsViewController: UITableViewController {

    private var visits = [Visit]()
    private let currentLocation: CLLocation?
    
    private lazy var distanceFormatter: MKDistanceFormatter = {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .Abbreviated
        return formatter
    }()
    
    init(visits: [Visit], location: CLLocation?) {
        self.visits = visits
        currentLocation = location
        super.init(style: .Grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Visits"
        view.backgroundColor = StyleController.sharedController.backgroundColor
        
        tableView.backgroundColor = view.backgroundColor
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.registerNib(UINib(nibName: String(VisitCell), bundle: nil), forCellReuseIdentifier: String(VisitCell))
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(VisitsViewController.visitsDidUpdate),
            name: PersistentController.PersistentControllerVistsDidUpdate,
            object: nil
        )
    }
    
    // MARK: - Notifications
    
    func visitsDidUpdate() {
        visits = PersistentController.sharedController.visits()
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visits.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier(String(VisitCell), forIndexPath: indexPath) as? VisitCell else {
            fatalError("Expected to dequeue a 'VisitCell'.")
        }

        let visit = visits[indexPath.row]
        cell.configureCellWithVisit(visit)
        
        if let location = currentLocation {
            cell.distanceLabel.text = distanceFormatter.stringFromDistance(location.distanceFromLocation(location))
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let selectedVisit = visits[indexPath.row]
        let vc = EditViewController(visit: selectedVisit)
        presentViewController(vc, animated: true, completion: nil)
    }

}
