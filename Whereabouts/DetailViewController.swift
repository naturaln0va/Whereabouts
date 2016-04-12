
import UIKit
import MapKit

class DetailViewController: UITableViewController {
    
    private let locationToDisplay: Location
    private lazy var nearbyPhotos = [UIImage]()
    
    private lazy var mapHeaderImageView = UIImageView()
    private let mapHeaderHeight: CGFloat = 145.0
    private let mapHeaderContainerHeight: CGFloat = 500.0
    
    private lazy var dateTimeFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        formatter.dateStyle = .MediumStyle
        return formatter
    }()
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(11.0, weight: UIFontWeightRegular)
        label.textAlignment = .Center
        label.numberOfLines = 2
        label.text = ""
        label.sizeToFit()
        return label
    }()
    private lazy var messageBarButtonItem: UIBarButtonItem = UIBarButtonItem(customView: self.messageLabel)
    private lazy var actionBarButtonItem: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: #selector(DetailViewController.actionButtonPressed))
    private lazy var spaceBarButtonItem: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
    
    init(location: Location) {
        locationToDisplay = location
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = locationToDisplay.locationTitle ?? locationToDisplay.placemark?.name ?? locationToDisplay.placemark?.locality ?? "Location"
        view.backgroundColor = StyleController.sharedController.backgroundColor
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Edit,
            target: self,
            action: #selector(DetailViewController.editButtonPressed)
        )
        
        tableView = UITableView(frame: CGRect.zero, style: .Grouped)
        tableView.backgroundColor = view.backgroundColor
        tableView.registerNib(UINib(nibName: String(MapItemCell), bundle: nil), forCellReuseIdentifier: String(MapItemCell))
        tableView.registerNib(UINib(nibName: String(ContentDisplayCell), bundle: nil), forCellReuseIdentifier: String(ContentDisplayCell))
        tableView.registerNib(UINib(nibName: String(LocationInfoDisplayCell), bundle: nil), forCellReuseIdentifier: String(LocationInfoDisplayCell))
        
        toolbarItems = [spaceBarButtonItem, messageBarButtonItem, spaceBarButtonItem, actionBarButtonItem]
        
        if let crowFlyDistance = MKMapItem.mapItemForCurrentLocation().placemark.location?.distanceFromLocation(locationToDisplay.location) {
            updateMessageLabel(NSAttributedString(string: distanceString(crowFlyDistance)))
        }
        
        getDistanceFromLocation()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        guard tableView.tableHeaderView == nil else {
            return
        }
        
        let options = MKMapSnapshotOptions()
        options.region = MKCoordinateRegion(
            center: locationToDisplay.location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 1 / 2, longitudeDelta: 1 / 2)
        )
        options.showsPointsOfInterest = true
        options.size = CGSize(width: self.view.bounds.width, height: self.view.bounds.width)
        options.mapType = .Hybrid
        
        MKMapSnapshotter(options: options).startWithCompletionHandler { snapshot, error in
            if let e = error {
                print("Error creating a snapshot of a location: \(e)")
            }
            
            if let shot = snapshot {
                let containerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.mapHeaderContainerHeight))
                containerView.clipsToBounds = true
                self.tableView.tableHeaderView = containerView
                
                let imageView = UIImageView(image: shot.image)
                imageView.frame = CGRect(
                    x: 0,
                    y: self.mapHeaderContainerHeight - self.mapHeaderHeight,
                    width: self.view.bounds.width,
                    height: self.mapHeaderHeight
                )
                imageView.contentMode = .ScaleAspectFill
                imageView.alpha = 0
                
                containerView.addSubview(imageView)
                self.mapHeaderImageView = imageView
                
                UIView.animateWithDuration(0.25, animations: {
                    imageView.alpha = 1
                }, completion: { _ in
                    containerView.backgroundColor = UIColor.blackColor()
                })
                
                self.refreshTableViewInsets()
            }
        }
    }
    
    // MARK: - Actions
    @objc private func editButtonPressed() {
        print("Pressed the edit button, yay.")
    }
    
    @objc private func actionButtonPressed() {
        var items = [AnyObject]()
        items.append(locationToDisplay.shareableString)
        
        if let url = locationToDisplay.location.vCardURL() {
            items.append(url)
        }
        
        if let mapItem = locationToDisplay.mapItem {
            items.append(mapItem)
        }
        
        let activityViewController: UIActivityViewController = UIActivityViewController(
            activityItems: items,
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
    
    // MARK: - Helpers
    private func refreshTableViewInsets() {
        let top: CGFloat = {
            let inset = topLayoutGuide.length
            
            if mapHeaderImageView.superview != nil {
                return -1 * (mapHeaderContainerHeight - mapHeaderHeight - inset)
            }
            else {
                return inset
            }
        }()
        
        tableView.contentInset = UIEdgeInsets(top: top, left: 0, bottom: 0, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
    }
    private func updateMessageLabel(updatedText: NSAttributedString?) {
        messageLabel.attributedText = updatedText
        messageLabel.sizeToFit()
    }
    
    private func getDistanceFromLocation() {
        let request = MKDirectionsRequest()
        
        request.source = MKMapItem.mapItemForCurrentLocation()
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: locationToDisplay.location.coordinate, addressDictionary: nil))
        
        let directions = MKDirections(request: request)
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        directions.calculateETAWithCompletionHandler { response, error in
            defer {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
            
            if let response = response {
                var responseString = ""
                responseString += distanceString(response.distance)
                
                let timeString = timeStringFromSeconds(response.expectedTravelTime)
                if timeString.characters.count > 0 {
                    
                    let hasDistance = responseString.characters.count > 0
                    let mut = NSMutableAttributedString()
                    
                    if hasDistance {
                        mut.appendAttributedString(NSAttributedString(string: responseString, attributes: [
                            NSForegroundColorAttributeName: UIColor.blackColor()
                            ]))
                        mut.appendAttributedString(NSAttributedString(string: "\n"))
                        mut.appendAttributedString(NSAttributedString(string: timeString + " away", attributes: [
                            NSForegroundColorAttributeName: UIColor(white: 0.45, alpha: 1.0)
                            ]))
                    }
                    else {
                        mut.appendAttributedString(NSAttributedString(string: timeString + " away", attributes: [
                            NSForegroundColorAttributeName: UIColor.blackColor()
                            ]))
                    }
                    
                    self.updateMessageLabel(mut)
                }
            }
        }
    }
    
    // MARK: - UIScrollView Overrides
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if mapHeaderImageView.superview == nil {
            return
        }
        
        let offset = scrollView.contentOffset.y
        let difference = offset - (-1 * scrollView.contentInset.top)
        
        if difference < 0 {
            // pulling down
            let scale = 1 + (-1 * difference) / mapHeaderHeight
            let transform = CGAffineTransformMakeScale(scale, scale)
            mapHeaderImageView.transform = CGAffineTransformTranslate(transform, 0, difference / 2 / scale)
            mapHeaderImageView.alpha = max(1 - (-1 * difference) / 150, 0.5)
        }
        else {
            mapHeaderImageView.transform = CGAffineTransformIdentity
            mapHeaderImageView.alpha = 1
        }
    }

    // MARK: - UITableView DataSource & Delegate
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return (section == 0 && (nearbyPhotos.count > 0 || locationToDisplay.textContent?.characters.count > 0)) ? 32.0 : 0.0001
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (nearbyPhotos.count > 0 || locationToDisplay.textContent?.characters.count > 0) ? 2 : 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if locationToDisplay.mapItem != nil {
                return 3
            }
            else if locationToDisplay.placemark != nil {
                return 2
            }
            else {
                return 1
            }
        }
        else if section == 1 {
            var rows = 0
            
            if nearbyPhotos.count > 0 {
                rows += 1
            }
                
            if locationToDisplay.textContent?.characters.count > 0 {
                rows += 1
            }
            
            return rows
        }
        else {
            fatalError("WARNING: Failed to handle section: \(section) in 'numberOfRowsInSection'.")
        }
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 0 {
            if locationToDisplay.placemark != nil && (indexPath.row == 0 || indexPath.row == 1) {
                return true
            }
            else {
                return false
            }
        }
        else if indexPath.section == 1 {
            if nearbyPhotos.count > 0 && indexPath.row == 0 {
                return true
            }
            else {
                return false
            }
        }
        else {
            return false
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if let mapItem = locationToDisplay.mapItem {
                if indexPath.row == 0 {
                    guard let cell = tableView.dequeueReusableCellWithIdentifier(String(MapItemCell)) as? MapItemCell else {
                        fatalError("Expected to dequeue a 'MapItemCell'.")
                    }
                    
                    cell.nameLabel.text = mapItem.name
                    cell.phoneNumberLabel.text = mapItem.phoneNumber
                    
                    if let urlString = mapItem.url?.absoluteString where urlString.characters.count > 0 {
                        cell.webPageLabel.text = urlString
                    }
                    else {
                        cell.webPageLabel.text = "No website"
                    }
                    
                    return cell
                }
                else if indexPath.row == 1 {
                    guard let cell = tableView.dequeueReusableCellWithIdentifier(String(LocationInfoDisplayCell)) as? LocationInfoDisplayCell else {
                        fatalError("Expected to dequeue a 'LocationInfoDisplayCell'.")
                    }
                    
                    cell.typeLabel.text = "Address"
                    cell.locationLabel.text = mapItem.placemark.fullFormatedString()
                    
                    return cell
                }
                else if indexPath.row == 2 {
                    guard let cell = tableView.dequeueReusableCellWithIdentifier(String(LocationInfoDisplayCell)) as? LocationInfoDisplayCell else {
                        fatalError("Expected to dequeue a 'LocationInfoDisplayCell'.")
                    }
                    
                    cell.typeLabel.text = "Location"
                    
                    var locationInfo = [String]()
                    
                    locationInfo.append("Coordinate: \(stringFromCoordinate(locationToDisplay.coordinate))")
                    locationInfo.append("Altitude: \(altitudeString(locationToDisplay.location.altitude))")
                    locationInfo.append("Timestamp: \(dateTimeFormatter.stringFromDate(locationToDisplay.date))")
                    
                    cell.locationLabel.text = locationInfo.joinWithSeparator("\n")
                    
                    return cell
                }
                else {
                    fatalError("WARNING: Failed to handle row: \(indexPath.row) in 'cellForRowAtIndexPath'.")
                }
            }
            else if let place = locationToDisplay.placemark {
                if indexPath.row == 0 {
                    guard let cell = tableView.dequeueReusableCellWithIdentifier(String(LocationInfoDisplayCell)) as? LocationInfoDisplayCell else {
                        fatalError("Expected to dequeue a 'LocationInfoDisplayCell'.")
                    }
                    
                    cell.typeLabel.text = "Address"
                    cell.locationLabel.text = place.fullFormatedString()
                    
                    return cell
                }
                else if indexPath.row == 1 {
                    guard let cell = tableView.dequeueReusableCellWithIdentifier(String(LocationInfoDisplayCell)) as? LocationInfoDisplayCell else {
                        fatalError("Expected to dequeue a 'LocationInfoDisplayCell'.")
                    }
                    
                    cell.typeLabel.text = "Location"
                    
                    var locationInfo = [String]()
                    
                    locationInfo.append("Coordinate: \(stringFromCoordinate(locationToDisplay.coordinate))")
                    locationInfo.append("Altitude: \(altitudeString(locationToDisplay.location.altitude))")
                    locationInfo.append("Timestamp: \(dateTimeFormatter.stringFromDate(locationToDisplay.date))")
                    
                    cell.locationLabel.text = locationInfo.joinWithSeparator("\n")
                    
                    return cell
                }
                else {
                    guard let cell = tableView.dequeueReusableCellWithIdentifier(String(LocationInfoDisplayCell)) as? LocationInfoDisplayCell else {
                        fatalError("Expected to dequeue a 'LocationInfoDisplayCell'.")
                    }
                    
                    cell.typeLabel.text = "Location"
                    
                    var locationInfo = [String]()
                    
                    locationInfo.append("Coordinate: \(stringFromCoordinate(locationToDisplay.coordinate))")
                    locationInfo.append("Altitude: \(altitudeString(locationToDisplay.location.altitude))")
                    locationInfo.append("Timestamp: \(dateTimeFormatter.stringFromDate(locationToDisplay.date))")
                    
                    cell.locationLabel.text = locationInfo.joinWithSeparator("\n")
                    
                    return cell
                }
            }
            else {
                fatalError("WARNING: Failed to data type in 'cellForRowAtIndexPath'.")

            }
        }
        else if indexPath.section == 1 {
            if nearbyPhotos.count > 0 && locationToDisplay.textContent?.characters.count > 0 {
                if indexPath.row == 0 {
                    let photoCellIndetifier = "photoCell"
                    
                    var cell = tableView.dequeueReusableCellWithIdentifier(photoCellIndetifier)
                    if cell == nil {
                        cell = UITableViewCell(style: .Value1, reuseIdentifier: photoCellIndetifier)
                        cell?.textLabel?.text = "Nearby Photos"
                        cell?.accessoryType = .DisclosureIndicator
                    }
                    
                    cell?.detailTextLabel?.text = String(nearbyPhotos.count)
                    
                    return cell!
                }
                else if indexPath.row == 1 {
                    guard let cell = tableView.dequeueReusableCellWithIdentifier(String(ContentDisplayCell)) as? ContentDisplayCell else {
                        fatalError("Expected to dequeue a 'ContentDisplayCell'.")
                    }
                    
                    cell.contentLabel.text = locationToDisplay.textContent
                    
                    return cell
                }
                else {
                    fatalError("Failed to handle row: \(indexPath.row) in 'cellForRowAtIndexPath'.")
                }
            }
            else if nearbyPhotos.count > 0 {
                let photoCellIndetifier = "photoCell"
                
                var cell = tableView.dequeueReusableCellWithIdentifier(photoCellIndetifier)
                if cell == nil {
                    cell = UITableViewCell(style: .Value1, reuseIdentifier: photoCellIndetifier)
                    cell?.textLabel?.text = "Nearby Photos"
                    cell?.accessoryType = .DisclosureIndicator
                }
                
                cell?.detailTextLabel?.text = String(nearbyPhotos.count)
                
                return cell!
            }
            else if locationToDisplay.textContent?.characters.count > 0 {
                guard let cell = tableView.dequeueReusableCellWithIdentifier(String(ContentDisplayCell)) as? ContentDisplayCell else {
                    fatalError("Expected to dequeue a 'ContentDisplayCell'.")
                }
                
                cell.contentLabel.text = locationToDisplay.textContent
                
                return cell
            }
            else {
                fatalError("WARNING: Failed to data type in 'cellForRowAtIndexPath'.")
            }
        }
        else {
            fatalError("WARNING: Failed to handle section: \(indexPath.section) in 'cellForRowAtIndexPath'.")
        }
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if locationToDisplay.mapItem != nil {
                if indexPath.row == 0 {
                    return MapItemCell.cellHeight
                }
                else if indexPath.row == 1 {
                    return UITableViewAutomaticDimension
                }
                else if indexPath.row == 2 {
                    return UITableViewAutomaticDimension
                }
                else {
                    fatalError("Failed to handle row: \(indexPath.row) in 'estimatedHeightForRowAtIndexPath'.")
                }
            }
            else if locationToDisplay.placemark != nil {
                return UITableViewAutomaticDimension
            }
            else {
                return UITableViewAutomaticDimension
            }
        }
        else if indexPath.section == 1 {
            if nearbyPhotos.count > 0 && locationToDisplay.textContent?.characters.count > 0 {
                if indexPath.row == 0 {
                    return 44.0
                }
                else if indexPath.row == 1 {
                    return UITableViewAutomaticDimension
                }
                else {
                    fatalError("Failed to handle row: \(indexPath.row) in 'estimatedHeightForRowAtIndexPath'.")
                }
            }
            else if nearbyPhotos.count > 0 {
                return 44.0
            }
            else if locationToDisplay.textContent?.characters.count > 0 {
                return UITableViewAutomaticDimension
            }
            else {
                fatalError("WARNING: Failed to data type in 'estimatedHeightForRowAtIndexPath'.")
            }
        }
        else {
            fatalError("WARNING: Failed to handle section: \(indexPath.section) in 'estimatedHeightForRowAtIndexPath'.")
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if locationToDisplay.mapItem != nil {
                if indexPath.row == 0 {
                    return MapItemCell.cellHeight
                }
                else if indexPath.row == 1 {
                    return UITableViewAutomaticDimension
                }
                else if indexPath.row == 2 {
                    return UITableViewAutomaticDimension
                }
                else {
                    fatalError("Failed to handle row: \(indexPath.row) in 'heightForRowAtIndexPath'.")
                }
            }
            else if locationToDisplay.placemark != nil {
                return UITableViewAutomaticDimension
            }
            else {
                return UITableViewAutomaticDimension
            }
        }
        else if indexPath.section == 1 {
            if nearbyPhotos.count > 0 && locationToDisplay.textContent?.characters.count > 0 {
                if indexPath.row == 0 {
                    return 44.0
                }
                else if indexPath.row == 1 {
                    return UITableViewAutomaticDimension
                }
                else {
                    fatalError("Failed to handle row: \(indexPath.row) in 'heightForRowAtIndexPath'.")
                }
            }
            else if nearbyPhotos.count > 0 {
                return 44.0
            }
            else if locationToDisplay.textContent?.characters.count > 0 {
                return UITableViewAutomaticDimension
            }
            else {
                fatalError("WARNING: Failed to data type in 'heightForRowAtIndexPath'.")
            }
        }
        else {
            fatalError("WARNING: Failed to handle section: \(indexPath.section) in 'heightForRowAtIndexPath'.")
        }
    }

}
