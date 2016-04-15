
import UIKit
import MapKit

class AddViewController: UITableViewController {

    private lazy var titleSearchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.sizeToFit()
        bar.delegate = self
        bar.placeholder = "Search for place or address"
        bar.keyboardType = .Default
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).tintColor = StyleController.sharedController.mainTintColor
        return bar
    }()
    
    private lazy var completer: MKLocalSearchCompleter = {
        let completer = MKLocalSearchCompleter()
        completer.delegate = self
        completer.filterType = .LocationsAndQueries
        return completer
    }()
    
    private var completionResults: [MKLocalSearchCompletion]?
    
    private var searchedMapItems: [MKMapItem]? {
        didSet {
            if searchedMapItems != nil {
                searchType = .Results
            }
        }
    }
    
    private var location: CLLocation? {
        didSet {
            tableView.reloadData()
        }
    }
    
    private var placemark: CLPlacemark? {
        didSet {
            tableView.reloadData()
        }
    }
    
    private enum SearchType {
        case None
        case Completer
        case Results
    }
    
    private var searchType: SearchType = .None {
        didSet {
            tableView.reloadData()
        }
    }
    
    private var regionForSearching: MKCoordinateRegion? {
        if let location = location {
            return MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        }
        else {
            return nil
        }
    }
    
    private var isCurrentlyLocating = false {
        didSet {
            tableView.reloadData()
        }
    }
    
    private lazy var assistant = LocationAssistant()
    private var isFirstApperance = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Search"
        view.backgroundColor = StyleController.sharedController.backgroundColor
        
        navigationItem.titleView = titleSearchBar
        
        tableView = UITableView(frame: CGRect.zero, style: .Grouped)
        tableView.keyboardDismissMode = .Interactive
        tableView.backgroundColor = view.backgroundColor
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.registerNib(UINib(nibName: String(SearchResultCell), bundle: nil), forCellReuseIdentifier: String(SearchResultCell))
        tableView.registerNib(UINib(nibName: String(SearchCompleterCell), bundle: nil), forCellReuseIdentifier: String(SearchCompleterCell))
        tableView.registerNib(UINib(nibName: String(CurrentLocationCell), bundle: nil), forCellReuseIdentifier: String(CurrentLocationCell))
        
        assistant.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        titleSearchBar.becomeFirstResponder()
        
        if isFirstApperance {
            assistant.getLocation()
            isCurrentlyLocating = true
            
            isFirstApperance = false
        }
    }
    
    // MARK: - Helpers
    private func searchWithRequest(request: MKLocalSearchRequest, completion: MKLocalSearchCompletionHandler) {
        if let region = regionForSearching {
            request.region = region
        }
        
        let search = MKLocalSearch(request: request)
        search.startWithCompletionHandler(completion)
    }
    
    private func startCompleterWithText(searchText: String) {
        if searchText.characters.count > 0 {
            completer.queryFragment = searchText
        }
        else {
            completer.cancel()
            completionResults?.removeAll()
            searchType = searchedMapItems?.count > 0 ? .Results : .None
        }
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return searchType == .Completer ? 0.0001 : 32.0
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if tableView.numberOfSections > 1 && indexPath.section == 0 && searchType != .Completer {
            guard let cell = tableView.dequeueReusableCellWithIdentifier(String(CurrentLocationCell)) as? CurrentLocationCell else {
                fatalError("Expected to dequeue a 'CurrentLocationCell' or location was nil.")
            }
            
            if isCurrentlyLocating {
                cell.loadingActivityView.startAnimating()
            }
            else {
                cell.loadingActivityView.stopAnimating()
            }
            
            if let place = placemark {
                cell.locationLabel.text = stringFromAddress(place, withNewLine: true)
            }
            else if let location = location {
                cell.locationLabel.text = stringFromCoordinate(location.coordinate)
            }
            else {
                cell.locationLabel.text = "Location Error"
            }
            
            return cell
        }
        
        if searchType == .Completer {
            guard let cell = tableView.dequeueReusableCellWithIdentifier(String(SearchCompleterCell)) as? SearchCompleterCell else {
                fatalError("Expected to dequeue a 'SearchCompleterCell'.")
            }
            
            cell.configureCellWithResult(completionResults?[indexPath.row])
            
            return cell
        }
        else {
            guard let cell = tableView.dequeueReusableCellWithIdentifier(String(SearchResultCell)) as? SearchResultCell else {
                fatalError("Expected to dequeue a 'SearchResultCell'.")
            }
            
            cell.titleLabel.text = searchedMapItems?[indexPath.row].name
            cell.websiteLabel.text = searchedMapItems?[indexPath.row].url?.absoluteString ?? searchedMapItems?[indexPath.row].phoneNumber ?? "No Additional Info"
            
            if let place = searchedMapItems?[indexPath.row].placemark {
                cell.addressLabel.text = stringFromAddress(place, withNewLine: false)
                
                if let location = place.location, let currentLocation = self.location {
                    let formatter = MKDistanceFormatter()
                    
                    formatter.unitStyle = .Abbreviated
                    formatter.units = SettingsController.sharedController.isUnitStyleImperial ? .Imperial : .Metric
                    
                    cell.distanceLabel.text = formatter.stringFromDistance(currentLocation.distanceFromLocation(location))
                }
                else {
                    cell.distanceLabel.text = ""
                }
            }
            else {
                cell.addressLabel.text = "\(searchedMapItems?[indexPath.row].url)"
                cell.distanceLabel.text = ""
            }
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        titleSearchBar.endEditing(true)
        
        if tableView.numberOfSections > 1 && indexPath.section == 0 && searchType != .Completer {
            if let currentLocation = location {
                let newLocation = Location(location: currentLocation)
                newLocation.placemark = placemark
                
                navigationController?.pushViewController(EditViewController(location: newLocation), animated: true)
            }
        }
        else if searchType == .Completer {
            if let results = completionResults {
                searchWithRequest(MKLocalSearchRequest(completion: results[indexPath.row])) { response, error in
                    if let response = response where error == nil {
                        self.searchedMapItems = response.mapItems
                        self.titleSearchBar.endEditing(true)
                    }
                    else {
                        print("Error searching for \(results[indexPath.row]). Error: \(error)")
                    }
                }
            }
        }
        else if let results = searchedMapItems where searchType == .Results {
            if let newLocation = Location(mapItem: results[indexPath.row]) {
                navigationController?.pushViewController(EditViewController(location: newLocation), animated: true)
            }
        }
        else {
            fatalError("ERROR: Failed to handle row in didSelectRowAtIndexPath.")
        }
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchType == .Completer {
            return nil
        }
        
        if tableView.numberOfSections > 1 && section == 0 && searchType != .Completer {
            return "Current Location"
        }
        else {
            return searchedMapItems?.count > 0 ? "Search Results" : nil
        }
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if tableView.numberOfSections > 1 && indexPath.section == 0 && searchType != .Completer {
            return CurrentLocationCell.cellHeight
        }
        else {
            return searchType == .Results ? SearchResultCell.cellHeight : SearchCompleterCell.cellHeight
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.numberOfSections > 1 && section == 0 && searchType != .Completer {
            return 1
        }
        
        if searchType == .Completer {
            return completionResults?.count ?? 0
        }
        else {
            return searchedMapItems?.count ?? 0
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return searchType == .Completer ? 1 : (location == nil ? 1 : 2)
    }

}

// MARK: - LocationAssistantDelegate
extension AddViewController: LocationAssistantDelegate {
    
    func locationAssistantReceivedLocation(location: CLLocation, finished: Bool) {
        self.location = location
        
        if finished {
            assistant.getAddressForLocation(location)
        }
    }
    
    func locationAssistantReceivedAddress(placemark: CLPlacemark) {
        self.placemark = placemark
        isCurrentlyLocating = false
    }
    
    func locationAssistantFailedToGetAddress() {
        isCurrentlyLocating = false
    }
    
    func locationAssistantFailedToGetLocation() {
        isCurrentlyLocating = false
    }
    
    func locationAssistantAuthorizationNeeded() {
        let accessVC = LocationAccessViewController()
        accessVC.delegate = self
        
        if titleSearchBar.isFirstResponder() {
            titleSearchBar.endEditing(true)
        }

        presentViewController(accessVC, animated: true, completion:  nil)
    }
    
    func locationAssistantAuthorizationDenied() {
        let accessVC = LocationAccessViewController()
        accessVC.delegate = self
        
        if titleSearchBar.isFirstResponder() {
            titleSearchBar.endEditing(true)
        }
        
        presentViewController(accessVC, animated: true, completion:  nil)
    }
    
}

extension AddViewController: LocationAccessViewControllerDelegate {
    
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


// MARK: - MKLocalSearchCompleterDelegate
extension AddViewController: MKLocalSearchCompleterDelegate {
    
    func completerDidUpdateResults(completer: MKLocalSearchCompleter) {
        completionResults = completer.results
        
        if searchType != .Completer {
            searchType = .Completer
        }
        
        tableView.reloadData()
    }
    
    func completer(completer: MKLocalSearchCompleter, didFailWithError error: NSError) {
        print("Failed to complete search: \(error)")
    }
    
}

// MARK: - UISearchBarDelegate
extension AddViewController: UISearchBarDelegate {
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        startCompleterWithText(searchText)
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        
        if let searchText = searchBar.text {
            startCompleterWithText(searchText)
        }
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.endEditing(true)
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBar.text
        
        searchWithRequest(request) { response, error in
            if let response = response where error == nil {
                self.searchedMapItems = response.mapItems
                searchBar.endEditing(true)
            }
            else {
                print("Error searching for \(searchBar.text). Error: \(error)")
            }
        }
    }
    
}
