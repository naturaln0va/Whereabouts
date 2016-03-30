
import UIKit
import MapKit

class AddViewController: UITableViewController {

    private lazy var titleSearchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.delegate = self
        bar.placeholder = "Search for place or address"
        bar.sizeToFit()
        return bar
    }()
    
    private lazy var completer: MKLocalSearchCompleter = {
        let completer = MKLocalSearchCompleter()
        completer.delegate = self
        completer.filterType = .LocationsAndQueries
        return completer
    }()
    
    private var completionResults: [MKLocalSearchCompletion]? {
        didSet {
            if completionResults != nil { tableView.reloadData() }
        }
    }
    
    private var location: CLLocation? {
        didSet {
            tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .None)
        }
    }
    
    private enum SearchType {
        case Completer
        case Results
    }
    
    private var searchType: SearchType = .Completer {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Search"
        view.backgroundColor = StyleController.sharedController.backgroundColor
        
        navigationItem.titleView = titleSearchBar
        
        tableView.backgroundColor = view.backgroundColor
        tableView = UITableView(frame: CGRect.zero, style: .Grouped)
        tableView.registerNib(UINib(nibName: String(SearchResultCell), bundle: nil), forCellReuseIdentifier: String(SearchResultCell))
        tableView.registerNib(UINib(nibName: String(SearchCompleterCell), bundle: nil), forCellReuseIdentifier: String(SearchCompleterCell))
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        titleSearchBar.becomeFirstResponder()
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return searchType == .Results ? SearchResultCell.cellHeight : SearchCompleterCell.cellHeight
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return searchType == .Results ? SearchResultCell.cellHeight : SearchCompleterCell.cellHeight
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchType == .Completer {
            return completionResults?.count ?? 0
        }
        else {
            return 0
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return location == nil ? 1 : 2
    }

}

extension AddViewController: MKLocalSearchCompleterDelegate {
    
    func completerDidUpdateResults(completer: MKLocalSearchCompleter) {
        completionResults = completer.results
    }
    
    func completer(completer: MKLocalSearchCompleter, didFailWithError error: NSError) {
        print("Failed to complete search: \(error)")
    }
    
}

extension AddViewController: UISearchBarDelegate {
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.characters.count > 0 {
            completer.queryFragment = searchText
        }
        else {
            completer.cancel()
            completionResults?.removeAll()
        }
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.endEditing(true)
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        // attempt search.
        // if successful resign the responder of the searchbar so the user may select a location
    }
    
}
