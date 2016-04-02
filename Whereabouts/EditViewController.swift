
import UIKit
import MapKit

class EditViewController: UITableViewController {
    
    private let location: Location
    private var shouldContinueUpdatingUserLocaiton = true
    
    private lazy var dateTimeFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        formatter.dateStyle = .MediumStyle
        return formatter
    }()
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        return mapView
    }()
    
    private var shouldDisplayAddress = true {
        didSet {
            if let _ = location.mapItem {
                tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 1, inSection: 0)], withRowAnimation: .Automatic)
            }
            else if let _ = location.placemark {
                tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
            }
        }
    }
    
    init(location: Location) {
        self.location = location

        super.init(nibName: nil, bundle: nil)
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = location.placemark?.locality ?? "New Location"
        view.backgroundColor = StyleController.sharedController.backgroundColor
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Save,
            target: self,
            action: #selector(EditViewController.saveButtonPressed)
        )
        
        tableView = UITableView(frame: CGRect.zero, style: .Grouped)
        tableView.keyboardDismissMode = .Interactive
        tableView.backgroundColor = view.backgroundColor

        tableView.registerNib(UINib(nibName: String(MapItemCell), bundle: nil), forCellReuseIdentifier: String(MapItemCell))
        tableView.registerNib(UINib(nibName: String(LocationInfoDisplayCell), bundle: nil), forCellReuseIdentifier: String(LocationInfoDisplayCell))
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let _ = location.mapItem where tableView.tableHeaderView == nil {
            mapView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 145)
            tableView.tableHeaderView = mapView
            
            mapView.addAnnotation(location)
            mapView.showAnnotations(mapView.annotations, animated: false)
            mapView.delegate = self
        }
    }
    
    // MARK: - Actions
    internal func saveButtonPressed() {
        PersistentController.sharedController.saveLocation(location)
        CloudController.sharedController.saveLocalLocationToCloud(location, completion: nil)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let item = location.mapItem {
            if indexPath.row == 0 {
                guard let cell = tableView.dequeueReusableCellWithIdentifier(String(MapItemCell)) as? MapItemCell else {
                    fatalError("Expected to dequeue a 'MapItemCell'.")
                }
                
                cell.nameLabel.text = item.name
                cell.phoneNumberLabel.text = item.phoneNumber
                
                if let urlString = item.url?.absoluteString {
                    cell.webPageLabel.text = urlString
                }
                
                return cell
            }
            else if indexPath.row == 1 {
                guard let cell = tableView.dequeueReusableCellWithIdentifier(String(LocationInfoDisplayCell)) as? LocationInfoDisplayCell else {
                    fatalError("Expected to dequeue a 'LocationInfoDisplayCell'.")
                }
                
                if shouldDisplayAddress {
                    cell.typeLabel.text = "Address"
                    cell.locationLabel.text = item.placemark.fullFormatedString()
                }
                else {
                    cell.typeLabel.text = "Location"
                    
                    var locationInfo = [String]()
                    
                    locationInfo.append("Coordinate: \(stringFromCoordinate(location.location.coordinate))")
                    locationInfo.append("Altitude: \(altitudeString(location.location.altitude))")
                    locationInfo.append("Timestamp: \(dateTimeFormatter.stringFromDate(location.date))")
                    
                    cell.locationLabel.text = locationInfo.joinWithSeparator("\n")
                }
                
                return cell
            }
            else {
                fatalError("ERROR: Failed to handle all rows for a mapItem datasource in cellForRowAtIndexPath.")
            }
        }
        else if let place = location.placemark {
            guard let cell = tableView.dequeueReusableCellWithIdentifier(String(LocationInfoDisplayCell)) as? LocationInfoDisplayCell else {
                fatalError("Expected to dequeue a 'LocationInfoDisplayCell'.")
            }
            
            if shouldDisplayAddress {
                cell.typeLabel.text = "Address"
                cell.locationLabel.text = place.fullFormatedString()
            }
            else {
                cell.typeLabel.text = "Location"
                
                var locationInfo = [String]()
                
                locationInfo.append("Coordinate: \(stringFromCoordinate(location.location.coordinate))")
                locationInfo.append("Altitude: \(altitudeString(location.location.altitude))")
                locationInfo.append("Timestamp: \(dateTimeFormatter.stringFromDate(location.date))")
                
                cell.locationLabel.text = locationInfo.joinWithSeparator("\n")
            }
            
            return cell
        }
        else {
            guard let cell = tableView.dequeueReusableCellWithIdentifier(String(LocationInfoDisplayCell)) as? LocationInfoDisplayCell else {
                fatalError("Expected to dequeue a 'LocationInfoDisplayCell'.")
            }
            
            cell.typeLabel.text = "Location"
            
            var locationInfo = [String]()
            
            locationInfo.append("Coordinate: \(stringFromCoordinate(location.location.coordinate))")
            locationInfo.append("Altitude: \(altitudeString(location.location.altitude))")
            locationInfo.append("Timestamp: \(dateTimeFormatter.stringFromDate(location.date))")
            
            cell.locationLabel.text = locationInfo.joinWithSeparator("\n")
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let _ = location.mapItem {
            if indexPath.row == 1 {
                shouldDisplayAddress = !shouldDisplayAddress
            }
        }
        else if let _ = location.placemark {
            shouldDisplayAddress = !shouldDisplayAddress
        }
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if let _ = location.mapItem {
            if indexPath.row == 1 {
                return true
            }
            else {
                return false
            }
        }
        if let _ = location.placemark {
            return true
        }
        
        return false
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let _ = location.mapItem {
            if indexPath.row == 0 {
                return MapItemCell.cellHeight
            }
            else if indexPath.row == 1 {
                return LocationInfoDisplayCell.cellHeight
            }
            else {
                fatalError("ERROR: Failed to handle all rows for a mapItem datasource in estimatedHeightForRowAtIndexPath.")
            }
        }
        else {
            return LocationInfoDisplayCell.cellHeight
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let _ = location.mapItem {
            if indexPath.row == 0 {
                return MapItemCell.cellHeight
            }
            else if indexPath.row == 1 {
                return LocationInfoDisplayCell.cellHeight
            }
            else {
                fatalError("ERROR: Failed to handle all rows for a mapItem datasource in heightForRowAtIndexPath.")
            }
        }
        else {
            return LocationInfoDisplayCell.cellHeight
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let _ = location.mapItem {
            return 2
        }
        else {
            return 1
        }
    }

}

extension EditViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        guard shouldContinueUpdatingUserLocaiton else { return }
        
        mapView.showAnnotations(mapView.annotations, animated: true)
        shouldContinueUpdatingUserLocaiton = false
    }
    
}
