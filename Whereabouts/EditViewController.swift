
import UIKit
import MapKit

protocol EditViewControllerDelegate: class {
    func editViewControllerDidEditLocation(viewController: EditViewController, editedLocation: Location)
}

class EditViewController: UITableViewController {
    
    private var locationToEdit: Location?
    private var shouldContinueUpdatingUserLocaiton = true
    
    private lazy var assistant = LocationAssistant()
    
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
        mapView.tintColor = StyleController.sharedController.mainTintColor
        return mapView
    }()
    
    private var shouldDisplayAddress = true {
        didSet {
            if let _ = locationToEdit?.mapItem {
                tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 1, inSection: 0)], withRowAnimation: .Automatic)
            }
            else if let _ = locationToEdit?.placemark {
                tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
            }
        }
    }
    
    weak var delegate: EditViewControllerDelegate?
    
    init(location: Location?) {
        super.init(nibName: nil, bundle: nil)
        
        self.locationToEdit = location
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = locationToEdit?.placemark?.locality ?? "New Location"
        view.backgroundColor = StyleController.sharedController.backgroundColor
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Save,
            target: self,
            action: #selector(EditViewController.saveButtonPressed)
        )
        
        if navigationController?.viewControllers.count == 1 {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .Cancel,
                target: self,
                action: #selector(EditViewController.cancelButtonPressed)
            )
        }
        
        tableView = UITableView(frame: CGRect.zero, style: .Grouped)
        tableView.keyboardDismissMode = .OnDrag
        tableView.backgroundColor = view.backgroundColor
        tableView.registerNib(UINib(nibName: String(MapItemCell), bundle: nil), forCellReuseIdentifier: String(MapItemCell))
        tableView.registerNib(UINib(nibName: String(LocationInfoDisplayCell), bundle: nil), forCellReuseIdentifier: String(LocationInfoDisplayCell))
        tableView.registerNib(UINib(nibName: String(TextContentCell), bundle: nil), forCellReuseIdentifier: String(TextContentCell))
        tableView.registerNib(UINib(nibName: String(ColorPreviewCell), bundle: nil), forCellReuseIdentifier: String(ColorPreviewCell))
        tableView.registerNib(UINib(nibName: String(TextEntryCell), bundle: nil), forCellReuseIdentifier: String(TextEntryCell))
        
        if locationToEdit == nil || locationToEdit?.placemark == nil {
            navigationItem.rightBarButtonItem?.enabled = false
            assistant.delegate = self
            assistant.getLocation()
            title = "Locating..."
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if tableView.tableHeaderView == nil {
            mapView.delegate = self
            mapView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 145)
            tableView.tableHeaderView = mapView
            
            if let location = locationToEdit, let _ = locationToEdit?.mapItem {
                mapView.addAnnotation(location)
                mapView.showAnnotations(mapView.annotations, animated: false)
            }
        }
    }
    
    // MARK: - Actions
    @objc private func cancelButtonPressed() {
        dismiss()
    }
    
    @objc private func saveButtonPressed() {
        if let titleCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as? TextEntryCell {
            locationToEdit?.locationTitle = titleCell.textField.text
        }
        
        if let contentCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 1)) as? TextContentCell {
            locationToEdit?.textContent = contentCell.textView.text
        }
        
        if let location = locationToEdit {
            PersistentController.sharedController.saveLocation(location)
            delegate?.editViewControllerDidEditLocation(self, editedLocation: location)
            dismiss()
        }
    }
    
    // MARK: - Helpers
    
    private func dismiss() {
        view.endEditing(true)
        
        if delegate != nil {
            navigationController?.popViewControllerAnimated(true)
        }
        else {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 32.0 : 0.0001
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if let item = locationToEdit?.mapItem {
                if indexPath.row == 0 {
                    guard let cell = tableView.dequeueReusableCellWithIdentifier(String(MapItemCell)) as? MapItemCell else {
                        fatalError("Expected to dequeue a 'MapItemCell'.")
                    }
                    
                    cell.configureWithMapItem(item)
                    
                    return cell
                }
                else if indexPath.row == 1 {
                    guard let location = locationToEdit, let cell = tableView.dequeueReusableCellWithIdentifier(String(LocationInfoDisplayCell)) as? LocationInfoDisplayCell else {
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
                    fatalError("ERROR: Failed to handle row in 'cellForRowAtIndexPath'.")
                }
            }
            else if let place = locationToEdit?.placemark {
                guard let location = locationToEdit, let cell = tableView.dequeueReusableCellWithIdentifier(String(LocationInfoDisplayCell)) as? LocationInfoDisplayCell else {
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
                guard let location = locationToEdit, let cell = tableView.dequeueReusableCellWithIdentifier(String(LocationInfoDisplayCell)) as? LocationInfoDisplayCell else {
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
        else if indexPath.section == 1 {
            if indexPath.row == 0 {
                guard let cell = tableView.dequeueReusableCellWithIdentifier(String(TextEntryCell)) as? TextEntryCell else {
                    fatalError("Expected to dequeue a 'TextEntryCell'.")
                }
                
                cell.textField.text = locationToEdit?.locationTitle
                
                return cell
            }
            else {
                guard let cell = tableView.dequeueReusableCellWithIdentifier(String(TextContentCell)) as? TextContentCell else {
                    fatalError("Expected to dequeue a 'TextContentCell'.")
                }
                
                cell.textView.text = locationToEdit?.textContent
                
                return cell
            }
        }
        else {
            fatalError("ERROR: Failed to handle section, \(indexPath.section), in 'cellForRowAtIndexPath'.")
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let _ = locationToEdit?.mapItem {
            if indexPath.row == 1 {
                shouldDisplayAddress = !shouldDisplayAddress
            }
        }
        else if let _ = locationToEdit?.placemark {
            shouldDisplayAddress = !shouldDisplayAddress
        }
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 1 {
            return false
        }
        else {
            if let _ = locationToEdit?.mapItem {
                if indexPath.row == 1 {
                    return true
                }
                else {
                    return false
                }
            }
            else if let _ = locationToEdit?.placemark {
                return true
            }
            else {
                return false
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if let _ = locationToEdit?.mapItem {
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
                if indexPath.row == 0 {
                    return LocationInfoDisplayCell.cellHeight
                }
                else {
                    fatalError("ERROR: Failed to handle all rows for a mapItem datasource in heightForRowAtIndexPath.")
                }
            }
        }
        else if indexPath.section == 1 {
            if indexPath.row == 0 {
                return TextEntryCell.cellHeight
            }
            else {
                return TextContentCell.cellHeight
            }
        }
        else {
            fatalError("ERROR: Failed to handle section, \(indexPath.section), in 'estimatedHeightForRowAtIndexPath'.")
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if let _ = locationToEdit?.mapItem {
                if indexPath.row == 0 {
                    return UITableViewAutomaticDimension
                }
                else if indexPath.row == 1 {
                    return UITableViewAutomaticDimension
                }
                else {
                    fatalError("ERROR: Failed to handle all rows for a mapItem datasource in heightForRowAtIndexPath.")
                }
            }
            else {
                if indexPath.row == 0 {
                    return UITableViewAutomaticDimension
                }
                else {
                    fatalError("ERROR: Failed to handle all rows for a mapItem datasource in heightForRowAtIndexPath.")
                }
            }
        }
        else if indexPath.section == 1 {
            if indexPath.row == 0 {
                return TextEntryCell.cellHeight
            }
            else {
                return TextContentCell.cellHeight
            }
        }
        else {
            fatalError("ERROR: Failed to handle section, \(indexPath.section), in 'estimatedHeightForRowAtIndexPath'.")
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if let _ = locationToEdit?.mapItem {
                return 2
            }
            else {
                return locationToEdit == nil ? 0 : 1
            }
        }
        else if section == 1 {
            return 2
        }
        else {
            fatalError("ERROR: Failed to handle section, \(section), in 'numberOfRowsInSection'.")
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

}

extension EditViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        guard shouldContinueUpdatingUserLocaiton else { return }
        
        mapView.showAnnotations(mapView.annotations, animated: true)
        shouldContinueUpdatingUserLocaiton = false
    }
    
}

extension EditViewController: LocationAssistantDelegate {
    
    func locationAssistantFailedToGetLocation() {
        print("Failed to get a location in 'EditViewController'.")
        
        if locationToEdit == nil {
            dismiss()
        }
    }
    
    func locationAssistantReceivedLocation(location: CLLocation, finished: Bool) {
        if let editingLocation = locationToEdit {
            editingLocation.location = location
        }
        else {
            locationToEdit = Location(location: location)
        }
        
        if finished {
            assistant.getAddressForLocation(location)
            navigationItem.rightBarButtonItem?.enabled = true
            title = "New Location"
        }
        
        tableView.reloadData()
    }
    
    func locationAssistantReceivedAddress(placemark: CLPlacemark) {
        locationToEdit?.placemark = placemark
        
        title = placemark.locality ?? "New Location"
        
        tableView.reloadData()
    }
    
    func locationAssistantAuthorizationNeeded() {
        let accessVC = LocationAccessViewController()
        accessVC.delegate = self
        
        presentViewController(accessVC, animated: true, completion:  nil)
    }
    
    func locationAssistantAuthorizationDenied() {
        print("Authorization denied in 'EditViewController'.")
        assistant.terminate()

        dismiss()
    }
    
}

extension EditViewController: LocationAccessViewControllerDelegate {
    
    func locationAccessViewControllerAccessGranted() {
        dismissViewControllerAnimated(true) {
            dispatch_async(dispatch_get_main_queue()) {
                self.assistant.requestWhenInUse()
            }
        }
    }
    
    func locationAccessViewControllerAccessDenied() {
        assistant.terminate()
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}
