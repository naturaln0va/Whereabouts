
import UIKit
import MapKit
import Photos
import SafariServices

class DetailViewController: UITableViewController, EditViewControllerDelegate {
    
    private var locationToDisplay: Location
    private lazy var nearbyAssets = [PHAsset]()
    
    private var isLoadingHeader = false
    
    private lazy var headerContainerView = UIView()
    private lazy var mapHeaderImageView = UIImageView()
    private let mapHeaderHeight: CGFloat = 145.0
    private let mapHeaderContainerHeight: CGFloat = 500.0
    
    private var directions: MKDirections?
    
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
    private lazy var navigateBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "directions-arrow"), style: .Plain, target: self, action: #selector(DetailViewController.navigateButtonPressed))
    
    init(location: Location) {
        locationToDisplay = location
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = StyleController.sharedController.backgroundColor
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Edit,
            target: self,
            action: #selector(DetailViewController.editButtonPressed)
        )
        
        if navigationController?.viewControllers.count == 1 {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .Cancel,
                target: self,
                action: #selector(DetailViewController.cancelButtonPressed)
            )
        }
        
        tableView = UITableView(frame: CGRect.zero, style: .Grouped)
        tableView.backgroundColor = view.backgroundColor
        tableView.registerNib(UINib(nibName: String(MapItemCell), bundle: nil), forCellReuseIdentifier: String(MapItemCell))
        tableView.registerNib(UINib(nibName: String(ContentDisplayCell), bundle: nil), forCellReuseIdentifier: String(ContentDisplayCell))
        tableView.registerNib(UINib(nibName: String(LocationInfoDisplayCell), bundle: nil), forCellReuseIdentifier: String(LocationInfoDisplayCell))
        
        toolbarItems = [navigateBarButtonItem, spaceBarButtonItem, messageBarButtonItem, spaceBarButtonItem, actionBarButtonItem]
        
        if let crowFlyDistance = MKMapItem.mapItemForCurrentLocation().placemark.location?.distanceFromLocation(locationToDisplay.location) {
            updateMessageLabel(NSAttributedString(string: distanceString(crowFlyDistance)))
        }
        
        getDistanceFromLocation()
        refreshTitle()
        
        getnearbyAssets { [unowned self] images in
            self.nearbyAssets = images
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        clearsSelectionOnViewWillAppear = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let directions = directions where directions.calculating {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            directions.cancel()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        guard tableView.tableHeaderView == nil && !isLoadingHeader else {
            return
        }
        
        headerContainerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: mapHeaderContainerHeight))
        headerContainerView.clipsToBounds = true
        tableView.tableHeaderView = headerContainerView
        
        refreshTableViewInsets()
        
        let imageCacheKey = locationToDisplay.identifier
        
        let imageRect = CGRect(
            x: 0,
            y: self.mapHeaderContainerHeight - self.mapHeaderHeight,
            width: self.view.bounds.width,
            height: self.mapHeaderHeight
        )
        
        let imageView = UIImageView()
        imageView.frame = imageRect
        imageView.contentMode = .ScaleAspectFill
        imageView.alpha = 0
        
        if let image = CacheController.imageForIdentifier(imageCacheKey) {
            imageView.image = image
            
            headerContainerView.addSubview(imageView)
            mapHeaderImageView = imageView
            
            UIView.animateWithDuration(0.25) {
                imageView.alpha = 1
            }
            return
        }
        
        let options = MKMapSnapshotOptions()
        options.region = MKCoordinateRegion(
            center: locationToDisplay.location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 1 / 5, longitudeDelta: 1 / 5)
        )
        options.showsPointsOfInterest = true
        options.size = CGSize(width: self.view.bounds.width, height: self.view.bounds.width)
        options.mapType = .Hybrid
        
        isLoadingHeader = true
        
        MKMapSnapshotter(options: options).startWithCompletionHandler { snapshot, error in
            if let e = error {
                print("Error creating a snapshot of a location: \(e)")
            }
            
            if let shot = snapshot {
                imageView.image = shot.image
                
                self.headerContainerView.addSubview(imageView)
                self.mapHeaderImageView = imageView
                
                CacheController.cacheImageWithIdentifier(shot.image, identifier: imageCacheKey)
                
                UIView.animateWithDuration(0.25) {
                    imageView.alpha = 1
                }
                
                self.isLoadingHeader = false
            }
        }
    }
    
    // MARK: - Actions
    @objc private func editButtonPressed() {
        let vc = EditViewController(location: locationToDisplay)
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func cancelButtonPressed() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @objc private func navigateButtonPressed() {
        let mapItem = self.locationToDisplay.mapItem ?? MKMapItem(placemark: MKPlacemark(coordinate: self.locationToDisplay.location.coordinate, addressDictionary: nil))
        mapItem.name = self.title

        guard let url = NSURL(string: "comgooglemaps://?daddr=\(locationToDisplay.location.coordinate.latitude),\(locationToDisplay.location.coordinate.longitude)") where UIApplication.sharedApplication().canOpenURL(url) else {
            mapItem.openInMapsWithLaunchOptions([MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
            return
        }
        let alertController = UIAlertController(title: "Directions", message: nil, preferredStyle: .ActionSheet)
        
        alertController.addAction(UIAlertAction(title: "Apple Maps", style: .Default) { action in
            mapItem.openInMapsWithLaunchOptions([MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        })
        
        alertController.addAction(UIAlertAction(title: "Google Maps", style: .Default) { action in
            UIApplication.sharedApplication().openURL(url)
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        presentViewController(alertController, animated: true, completion: nil)
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
        let top: CGFloat = -1 * (mapHeaderContainerHeight - mapHeaderHeight - topLayoutGuide.length)
        tableView.contentInset = UIEdgeInsets(top: top, left: 0, bottom: navigationController?.toolbar.frame.height ?? 0, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
    }
    
    private func updateMessageLabel(updatedText: NSAttributedString?) {
        messageLabel.attributedText = updatedText
        messageLabel.sizeToFit()
    }
    
    private func refreshTitle() {
        if let locationTitle = locationToDisplay.locationTitle where locationTitle.characters.count > 0 {
            title = locationTitle
        }
        else if let mapName = locationToDisplay.mapItem?.name where mapName.characters.count > 0 {
            title = mapName
        }
        else if let cityName = locationToDisplay.placemark?.locality where cityName.characters.count > 0 {
            title = cityName
        }
        else {
            title = "Location"
        }
    }
    
    func getnearbyAssets(completion: [PHAsset] -> Void) {
        var assets = [PHAsset]()

        PHPhotoLibrary.requestAuthorization { status in
            if status == .Authorized {
                let options = PHFetchOptions()
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                let results = PHAsset.fetchAssetsWithMediaType(.Image, options: options)
                let manager = PHImageManager.defaultManager()
                let option = PHImageRequestOptions()
                option.synchronous = true
                
                results.enumerateObjectsUsingBlock { asset, idx, stop in
                    guard let assetWithLocationData = asset as? PHAsset where assetWithLocationData.location != nil else {
                        return
                    }
                    
                    if assetWithLocationData.location!.distanceFromLocation(self.locationToDisplay.location) < 150 {
                        assets.append(assetWithLocationData)
                    }
                }
                
            }
            
            defer {
                dispatch_async(dispatch_get_main_queue()) {
                    completion(assets)
                }
            }
        }
    }
    
    private func getDistanceFromLocation() {
        let request = MKDirectionsRequest()
        
        request.source = MKMapItem.mapItemForCurrentLocation()
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: locationToDisplay.location.coordinate, addressDictionary: nil))
        
        directions = MKDirections(request: request)
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        directions?.calculateETAWithCompletionHandler { response, error in
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
    
    // MARK: - EditViewControllerDelegate
    func editViewControllerDidEditLocation(viewController: EditViewController, editedLocation: Location) {
        locationToDisplay = editedLocation
        tableView.reloadData()
        refreshTitle()
    }
    
    // MARK: - UIScrollView Overrides
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if mapHeaderImageView.superview == nil {
            return
        }
        
        let offset = scrollView.contentOffset.y
        let difference = offset - (-1 * scrollView.contentInset.top)
        
        if difference < 0 {
            let scale = 1 + (-1 * difference) / mapHeaderHeight
            let transform = CGAffineTransformMakeScale(scale, scale)
            mapHeaderImageView.transform = CGAffineTransformTranslate(transform, 0, difference / 2 / scale)
        }
        else {
            mapHeaderImageView.transform = CGAffineTransformIdentity
        }
    }

    // MARK: - UITableView DataSource & Delegate
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return (section == 0 && (nearbyAssets.count > 0 || locationToDisplay.textContent?.characters.count > 0)) ? 32.0 : 0.0001
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (nearbyAssets.count > 0 || locationToDisplay.textContent?.characters.count > 0) ? 2 : 1
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
            
            if nearbyAssets.count > 0 {
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
            if locationToDisplay.mapItem != nil {
                return indexPath.row == 0
            }
            else {
                return false
            }
        }
        else if indexPath.section == 1 {
            if nearbyAssets.count > 0 && indexPath.row == 0 {
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
        
        if let item = locationToDisplay.mapItem where indexPath == NSIndexPath(forRow: 0, inSection: 0) {
            var phoneNumber = String()
            var urlString = String()
            
            if let number = item.phoneNumber {
                phoneNumber = number
            }
            
            if let url = item.url?.absoluteString {
                urlString = url
            }
            
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            
            if let numberString = "telprompt://\(phoneNumber)".stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()), let numberURL = NSURL(string: numberString) where phoneNumber.characters.count > 0 {
                var titleString = "Call"
                if let name = item.name {
                    titleString += " \(name)"
                }
                
                alertController.addAction(UIAlertAction(title: titleString, style: .Default) { action in
                    UIApplication.sharedApplication().openURL(numberURL)
                })
            }
            
            if let url = item.url where urlString.characters.count > 0 {
                var titleString = "Visit"
                if let name = item.name {
                    titleString += " \(name)"
                }
                
                alertController.addAction(UIAlertAction(title: titleString, style: .Default) { action in
                    let safariVC = SFSafariViewController(URL: url)
                    safariVC.view.tintColor = StyleController.sharedController.mainTintColor
                    self.presentViewController(safariVC, animated: true, completion: nil)
                })
            }
            
            guard alertController.actions.count > 0 else {
                return
            }
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if let mapItem = locationToDisplay.mapItem {
                if indexPath.row == 0 {
                    guard let cell = tableView.dequeueReusableCellWithIdentifier(String(MapItemCell)) as? MapItemCell else {
                        fatalError("Expected to dequeue a 'MapItemCell'.")
                    }
                    
                    cell.configureWithMapItem(mapItem)
                    
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
            if nearbyAssets.count > 0 && locationToDisplay.textContent?.characters.count > 0 {
                if indexPath.row == 0 {
                    let photoCellIndetifier = "photoCell"
                    
                    var cell = tableView.dequeueReusableCellWithIdentifier(photoCellIndetifier)
                    if cell == nil {
                        cell = UITableViewCell(style: .Value1, reuseIdentifier: photoCellIndetifier)
                        cell?.textLabel?.text = "Nearby Photos"
                        cell?.accessoryType = .DisclosureIndicator
                    }
                    
                    cell?.detailTextLabel?.text = String(nearbyAssets.count)
                    
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
            else if nearbyAssets.count > 0 {
                let photoCellIndetifier = "photoCell"
                
                var cell = tableView.dequeueReusableCellWithIdentifier(photoCellIndetifier)
                if cell == nil {
                    cell = UITableViewCell(style: .Value1, reuseIdentifier: photoCellIndetifier)
                    cell?.textLabel?.text = "Nearby Photos"
                    cell?.accessoryType = .DisclosureIndicator
                }
                
                cell?.detailTextLabel?.text = String(nearbyAssets.count)
                
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
                    return LocationInfoDisplayCell.cellHeight
                }
                else if indexPath.row == 2 {
                    return LocationInfoDisplayCell.cellHeight
                }
                else {
                    fatalError("Failed to handle row: \(indexPath.row) in 'estimatedHeightForRowAtIndexPath'.")
                }
            }
            else if locationToDisplay.placemark != nil {
                return LocationInfoDisplayCell.cellHeight
            }
            else {
                return LocationInfoDisplayCell.cellHeight
            }
        }
        else if indexPath.section == 1 {
            if nearbyAssets.count > 0 && locationToDisplay.textContent?.characters.count > 0 {
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
            else if nearbyAssets.count > 0 {
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
                    return UITableViewAutomaticDimension
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
            if nearbyAssets.count > 0 && locationToDisplay.textContent?.characters.count > 0 {
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
            else if nearbyAssets.count > 0 {
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
