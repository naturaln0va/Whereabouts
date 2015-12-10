
import UIKit
import CoreLocation

protocol NewLocationViewControllerDelegate
{
    func newLocationViewControllerDidEditLocation(editedLocation: Location)
}


class NewLocationViewController: StyledViewController
{

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var bottomToolBar: UIToolbar!
    
    var accuracyBarButtonItem: UIBarButtonItem?
    var delegate: NewLocationViewControllerDelegate?
    var assistant: LocationAssistant?
    var locationToEdit: Location?
    var isFirstLoadForLocationEdit = true
    
    var selectedColor: UIColor?
    
    private lazy var loadingBarButtonItem: UIBarButtonItem = {
        let activityView = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activityView.color = ColorController.navBarBackgroundColor
        activityView.startAnimating()
        return UIBarButtonItem(customView: activityView)
    }()
    
    private lazy var refreshBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "refreshButtonPressed")
    }()
    
    private lazy var actionBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "actionButtonPressed")
    }()
    
    private lazy var spaceBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
    }()
    
    private lazy var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "EEEE MMM d"
        return formatter
    }()
    
    private let numberFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 7

        return formatter
    }()
    
    private var location: CLLocation? {
        didSet {
            tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .None)
        }
    }
    private var placemark: CLPlacemark? {
        didSet {
            tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
        }
    }
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        title = locationToEdit == nil ? "New Location" : locationToEdit!.title
        
        tableView.contentInset = UIEdgeInsets(top: 64.0, left: 0.0, bottom: 0.0, right: 0.0)
        
        bottomToolBar.items = [spaceBarButtonItem, loadingBarButtonItem]
        bottomToolBar.tintColor = ColorController.navBarBackgroundColor
        
        let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "saveBarButtonPressed")
        let leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelBarButtonPressed")
        
        navigationItem.rightBarButtonItem = rightBarButtonItem
        navigationItem.leftBarButtonItem = leftBarButtonItem
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = ColorController.backgroundColor
        tableView.registerNib(UINib(nibName: TextEntryCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: TextEntryCell.reuseIdentifier)
        tableView.registerNib(UINib(nibName: ColorPreviewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: ColorPreviewCell.reuseIdentifier)
        
        if let _ = assistant {
            assistant?.delegate = self
            assistant?.getLocation()
        }
        else if let editingLocation = locationToEdit {
            location = editingLocation.location
            placemark = editingLocation.placemark
            selectedColor = editingLocation.color
            
            if editingLocation.placemark == nil {
                assistant = LocationAssistant(viewController: self)
                assistant?.delegate = self
                assistant?.getAddressForLocation(editingLocation.location)
                bottomToolBar.items = [spaceBarButtonItem, loadingBarButtonItem]
            }
            else {
                bottomToolBar.items = nil
            }
        }
    }

    func refreshButtonPressed()
    {
        if let accuracyButton = accuracyBarButtonItem {
            bottomToolBar.items = [spaceBarButtonItem, accuracyButton, spaceBarButtonItem, loadingBarButtonItem]
        }
        else {
            bottomToolBar.items = [spaceBarButtonItem, loadingBarButtonItem]
        }
        
        if let editingLocation = locationToEdit {
            assistant?.getAddressForLocation(editingLocation.location)
        }
        else if let _ = assistant {
            assistant?.getLocation()
        }
    }
    
    func actionButtonPressed()
    {
        var activityItems = Array<AnyObject>()
        
        guard let locationToSave = location else {
            print("Tried to share without a locaiton!")
            return
        }
        
        if let placemark = placemark {
            activityItems.append("I'm at: \(stringFromAddress(placemark, withNewLine: true)).\nWhere are you?")
            activityItems.append(locationToSave)
        }
        else {
            activityItems.append("I'm at: \(stringFromCoordinate(locationToSave.coordinate)).\nWhere are you?")
            activityItems.append(locationToSave)
        }
        
        let activityViewController: UIActivityViewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        activityViewController.excludedActivityTypes = [
            UIActivityTypePrint,
            UIActivityTypeAssignToContact,
            UIActivityTypeSaveToCameraRoll,
            UIActivityTypeAddToReadingList,
            UIActivityTypePostToFlickr,
            UIActivityTypePostToVimeo
        ]
        
        presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    func saveBarButtonPressed()
    {
        guard let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? TextEntryCell, let title = cell.textField.text where title.characters.count > 0 else {
            let alert = UIAlertController(title: "No Title", message: "Please enter a title for this location.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        if let location = locationToEdit {
            PersistentController.sharedController.updateLocation(location, title: title, color: selectedColor, placemark: placemark)
            if let delegate = delegate {
                delegate.newLocationViewControllerDidEditLocation(location)
            }
        }
        else {
            guard let locationToSave = location, let items = bottomToolBar.items where !items.contains(loadingBarButtonItem) else {
                let alert = UIAlertController(title: "Sorry", message: "Please wait for an accurate location to be found.", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
                presentViewController(alert, animated: true, completion: nil)
                return
            }

            PersistentController.sharedController.saveLocation(title, color: selectedColor, placemark: placemark, location: locationToSave)
        }
        dismiss()
    }
    
    func cancelBarButtonPressed()
    {
        dismiss()
    }
    
    // MARK: - Private
    private func dismiss()
    {
        view.endEditing(true)
        if let _ = assistant {
            assistant?.terminate()
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}


extension NewLocationViewController: LocationAssistantDelegate
{
    
    func receivedLocation(location: CLLocation, finished: Bool)
    {
        self.location = location
        
        let formatter = NSNumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        let accuracyString = formatter.stringFromNumber(NSNumber(double: min(100, (SettingsController.sharedController.distanceAccuracy / location.horizontalAccuracy) * 100)))
        
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(12.0, weight: UIFontWeightRegular)
        label.textAlignment = .Center
        label.text = "\(accuracyString!)% Accurate"
        label.sizeToFit()
        let labelButton = UIBarButtonItem(customView: label)
        accuracyBarButtonItem = labelButton
        
        bottomToolBar.items = [spaceBarButtonItem, labelButton, spaceBarButtonItem, loadingBarButtonItem]
        
        if finished {
            assistant?.getAddressForLocation(location)
        }
    }
    
    func receivedAddress(placemark: CLPlacemark)
    {
        self.placemark = placemark
        
        if locationToEdit != nil {
            bottomToolBar.items = nil
        }
        else {
            if let accuracyButton = accuracyBarButtonItem {
                bottomToolBar.items = [actionBarButtonItem, spaceBarButtonItem, accuracyButton, spaceBarButtonItem, refreshBarButtonItem]
            }
            else {
                bottomToolBar.items = [actionBarButtonItem, spaceBarButtonItem, refreshBarButtonItem]
            }
        }
    }
    
    func authorizationDenied()
    {
        dismiss()
    }
    
    func failedToGetLocation()
    {
        if let accuracyButton = accuracyBarButtonItem {
            bottomToolBar.items = [actionBarButtonItem, spaceBarButtonItem, accuracyButton, spaceBarButtonItem, refreshBarButtonItem]
        }
        else if location != nil {
            bottomToolBar.items = [actionBarButtonItem, spaceBarButtonItem, refreshBarButtonItem]
        }
        else {
            bottomToolBar.items = [spaceBarButtonItem, refreshBarButtonItem]
        }
    }
    
    func failedToGetAddress()
    {
        if let accuracyButton = accuracyBarButtonItem {
            bottomToolBar.items = [actionBarButtonItem, spaceBarButtonItem, accuracyButton, spaceBarButtonItem, refreshBarButtonItem]
        }
        else {
            bottomToolBar.items = [actionBarButtonItem, spaceBarButtonItem, refreshBarButtonItem]
        }
    }
    
}


//MARK: - TableView Deleagte & DataSource
extension NewLocationViewController: UITableViewDelegate, UITableViewDataSource
{
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                return tableView.dequeueReusableCellWithIdentifier(TextEntryCell.reuseIdentifier, forIndexPath: indexPath)
            }
            else {
                return tableView.dequeueReusableCellWithIdentifier(ColorPreviewCell.reuseIdentifier, forIndexPath: indexPath)
            }
        }
        else {
            return UITableViewCell(style: .Value1, reuseIdentifier: "infoCell")
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
    {
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                guard let cell = cell as? TextEntryCell else {
                    fatalError("Expected to display a 'TextEntryCell' cell.")
                }
                if let editingLocation = locationToEdit where isFirstLoadForLocationEdit {
                    cell.textField.text = editingLocation.title
                    isFirstLoadForLocationEdit = false
                }
                cell.textField.placeholder = "Enter a title"
            }
            else if indexPath.row == 1 {
                guard let cell = cell as? ColorPreviewCell else {
                    fatalError("Expected to display a 'ColorPreviewCell' cell.")
                }
                cell.colorToDisplay = selectedColor
                cell.accessoryType = .DisclosureIndicator
            }
        }
        else {
            if indexPath.row == 0 {
                cell.textLabel?.text = "Date"
                cell.detailTextLabel?.text = location == nil ? "" : dateFormatter.stringFromDate(location!.timestamp)
            }
            else if indexPath.row == 1 {
                cell.textLabel?.text = "Latitude"
                cell.detailTextLabel?.text = location == nil ? "" : numberFormatter.stringFromNumber(NSNumber(double: location!.coordinate.latitude))!
            }
            else if indexPath.row == 2 {
                cell.textLabel?.text = "Longitude"
                cell.detailTextLabel?.text = location == nil ? "" : numberFormatter.stringFromNumber(NSNumber(double: location!.coordinate.longitude))!
            }
            else if indexPath.row == 3 {
                if let placemark = placemark {
                    cell.textLabel?.text = "Address"
                    cell.detailTextLabel?.text = stringFromAddress(placemark, withNewLine: true)
                }
                else {
                    cell.textLabel?.text = "Altitude"
                    cell.detailTextLabel?.text = location == nil ? "" : altitudeString(location!.altitude)
                }
            }
            else if indexPath.row == 4 {
                cell.textLabel?.text = "Altitude"
                cell.detailTextLabel?.text = location == nil ? "" : altitudeString(location!.altitude)
            }
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                if let cell = tableView.cellForRowAtIndexPath(indexPath) as? TextEntryCell {
                    cell.textField.becomeFirstResponder()
                }
            }
            else {
                let colorSelector = ColorSelectionViewController(collectionViewLayout: DefaultLayout())
                colorSelector.delegate = self
                navigationController?.pushViewController(colorSelector, animated: true)
            }

        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0 {
            return 2
        }
        else {
            var numberOfRows = 4
            if placemark != nil {
                numberOfRows++
            }
            return numberOfRows

        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 35.0
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.0001
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                return TextEntryCell.cellHeight
            }
            else {
                return ColorPreviewCell.cellHeight
            }
        }
        else {
            return 44.0
        }
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        if indexPath.row == 1 && indexPath.section == 0 {
            return true
        }
        return false
    }
    
}


extension NewLocationViewController: ColorSelectionViewControllerDelegate
{
    
    func colorSelectionViewControllerDidSelectColor(color: UIColor)
    {
        selectedColor = color
        tableView.reloadData()
    }
    
}
