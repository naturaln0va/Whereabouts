
import UIKit
import MapKit

class AddViewController: UITableViewController {

    private lazy var titleSearchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.delegate = self
        bar.placeholder = "Search for place or address"
        bar.sizeToFit()
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
    
    private lazy var assistant = LocationAssistant()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Search"
        view.backgroundColor = StyleController.sharedController.backgroundColor
        
        navigationItem.titleView = titleSearchBar
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "close-cross"),
            landscapeImagePhone: nil, style: .Plain,
            target: self,
            action: #selector(AddViewController.closeButtonPressed)
        )
        
        tableView.backgroundColor = view.backgroundColor
        tableView = UITableView(frame: CGRect.zero, style: .Grouped)
        tableView.registerNib(UINib(nibName: String(SearchResultCell), bundle: nil), forCellReuseIdentifier: String(SearchResultCell))
        tableView.registerNib(UINib(nibName: String(SearchCompleterCell), bundle: nil), forCellReuseIdentifier: String(SearchCompleterCell))
        tableView.registerNib(UINib(nibName: String(CurrentLocationCell), bundle: nil), forCellReuseIdentifier: String(CurrentLocationCell))
        tableView.keyboardDismissMode = .Interactive
        
        assistant.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        titleSearchBar.becomeFirstResponder()
        assistant.getLocation()
    }
    
    // MARK: - Actions
    internal func closeButtonPressed() {
        titleSearchBar.endEditing(true)
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Helpers
    private func searchWithQuery(query: String?, completion: MKLocalSearchCompletionHandler) {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = query
        
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
            guard let location = location, let cell = tableView.dequeueReusableCellWithIdentifier(String(CurrentLocationCell)) as? CurrentLocationCell else {
                fatalError("Expected to dequeue a 'CurrentLocationCell' or location was nil.")
            }
            
            cell.coordinateLabel.text = stringFromCoordinate(location.coordinate)
            
            return cell
        }
        
        if searchType == .Completer {
            guard let cell = tableView.dequeueReusableCellWithIdentifier(String(SearchCompleterCell)) as? SearchCompleterCell else {
                fatalError("Expected to dequeue a 'SearchCompleterCell'.")
            }
            
            cell.mainTextLabel.text = ""
            cell.secondaryTextLabel.text = ""
            
            if let mainString = completionResults?[indexPath.row].title {
                let mainAttrText = NSMutableAttributedString(string: mainString)
                
                if let ranges = completionResults?[indexPath.row].titleHighlightRanges {
                    for range in ranges {
                        mainAttrText.addAttributes(
                            [NSBackgroundColorAttributeName: UIColor(red: 0.95,  green: 0.77,  blue: 0.05, alpha: 0.50)],
                            range: range.rangeValue
                        )
                    }
                }
                
                cell.mainTextLabel.attributedText = mainAttrText
            }
            
            if let secondaryString = completionResults?[indexPath.row].subtitle {
                let secondaryAttrText = NSMutableAttributedString(string: secondaryString)
                
                if let ranges = completionResults?[indexPath.row].subtitleHighlightRanges {
                    for range in ranges {
                        secondaryAttrText.addAttributes(
                            [NSBackgroundColorAttributeName: UIColor(red: 0.95,  green: 0.77,  blue: 0.05, alpha: 0.50)],
                            range: range.rangeValue
                        )
                    }
                }
                
                cell.secondaryTextLabel.text = secondaryString
            }
            
            return cell
        }
        else {
            guard let cell = tableView.dequeueReusableCellWithIdentifier(String(SearchResultCell)) as? SearchResultCell else {
                fatalError("Expected to dequeue a 'SearchResultCell'.")
            }
            
            cell.titleLabel.text = searchedMapItems?[indexPath.row].name
            
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
        
        if searchType == .Completer {
            if let results = completionResults {
                let search = MKLocalSearch(request: MKLocalSearchRequest(completion: results[indexPath.row]))
                search.startWithCompletionHandler { response, error in
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
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
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

extension AddViewController: LocationAssistantDelegate {
    
    func locationAssistantReceivedLocation(location: CLLocation, finished: Bool) {
        self.location = location
    }
    
}

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
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchWithQuery(searchBar.text) { response, error in
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
