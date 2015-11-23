
import UIKit
import MapKit
import Photos


class LocationDetailViewController: UIViewController
{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photosCollectionView: UICollectionView!
    @IBOutlet weak var mapWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var locationInformationView: UIView!
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var coordinateLabel: UILabel!
    @IBOutlet weak var noPhotosLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet var collectionViewHeightConstraint: NSLayoutConstraint!

    var locationToDisplay: Location!
    var nearbyPhotos: Array<UIImage>?
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "editButtonPressed")
        
        photosCollectionView.delegate = self
        photosCollectionView.dataSource = self
        photosCollectionView.backgroundColor = UIColor.clearColor()
        photosCollectionView.collectionViewLayout = PhotosLayout()
        photosCollectionView.registerNib(UINib(nibName: PhotoCell.reuseIdentifer, bundle: nil), forCellWithReuseIdentifier: PhotoCell.reuseIdentifer)
        
        locationInformationView.layer.cornerRadius = 4.0
        locationInformationView.layer.shadowColor = UIColor.blackColor().CGColor
        locationInformationView.layer.shadowOpacity = 0.125
        locationInformationView.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        locationInformationView.layer.shadowRadius = 2.5
        
        mapView.delegate = self
        mapView.scrollEnabled = false
        mapView.rotateEnabled = false
        mapView.setRegion(MKCoordinateRegion(center: locationToDisplay.location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.052125, longitudeDelta: 0.052125)), animated: false)
        
        colorView.layer.cornerRadius = 10.0
        toolBar.tintColor = ColorController.navBarBackgroundColor
        noPhotosLabel.alpha = 0.0
        
        getNearbyPhotos { photos in
            if let photos = photos {
                self.noPhotosLabel.alpha = 0.0
                self.nearbyPhotos = photos
                self.photosCollectionView.reloadData()
            }
            else {
                self.noPhotosLabel.alpha = 1.0
            }
        }
        
        let request = MKDirectionsRequest()
        
        request.source = MKMapItem.mapItemForCurrentLocation()
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: locationToDisplay.location.coordinate, addressDictionary: nil))
        
        let directions = MKDirections(request: request)
        directions.calculateETAWithCompletionHandler { response, error in
            if let response = response where error == nil {
                var responseString = ""
                if #available(iOS 9.0, *) {
                    let distanceAway = SettingsController.sharedController.unitStyle ? response.distance * 0.00062137 : response.distance / 1000.0
                    if distanceAway > 0.75 {
                        let formatter = NSNumberFormatter()
                        formatter.minimumFractionDigits = 2
                        
                        if let formattedMileString = formatter.stringFromNumber(NSNumber(double: distanceAway)) {
                            responseString += "\(formattedMileString) \(SettingsController.sharedController.unitStyle ? "mi": "km"), "
                        }
                    }
                }
                
                let timeString = timeStringFromSeconds(response.expectedTravelTime)
                if timeString.characters.count > 0 {
                    responseString += "\(timeString) away"
                    self.locationToDisplay.distanceAndETAString = responseString
                    self.mapView.removeAnnotation(self.locationToDisplay)
                    self.mapView.addAnnotation(self.locationToDisplay)
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        refreshView()
    }
    
    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()
        mapWidthConstraint.constant = CGRectGetWidth(view.bounds)
    }
    
    // MARK: - Actions
    func editButtonPressed()
    {
        let newlocationVC = NewLocationViewController()
        newlocationVC.locationToEdit = locationToDisplay
        newlocationVC.delegate = self
        presentViewController(StyledNavigationController(rootViewController: newlocationVC), animated: true, completion: nil)
    }
    
    func annotationButtonPressed()
    {
        let placeToOpen = locationToDisplay.placemark == nil ? MKPlacemark(coordinate: locationToDisplay.location.coordinate, addressDictionary: nil) : MKPlacemark(placemark: locationToDisplay.placemark!)
        let mapItem = MKMapItem(placemark: placeToOpen)
        mapItem.name = locationToDisplay.title
        mapItem.openInMapsWithLaunchOptions(nil)
    }
    
    @IBAction func actionButtonPressed(sender: AnyObject)
    {
        let firstActivityItem = "I'm at \(locationToDisplay.shareableString()), where are you?"
        
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [firstActivityItem], applicationActivities: nil)
        
        activityViewController.excludedActivityTypes = [
            UIActivityTypePrint,
            UIActivityTypeAssignToContact,
            UIActivityTypeSaveToCameraRoll,
            UIActivityTypeAddToReadingList,
            UIActivityTypePostToFlickr,
            UIActivityTypePostToVimeo
        ]
        
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    func getNearbyPhotos(completion: Array<UIImage>? -> Void)
    {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .Authorized {
                let options = PHFetchOptions()
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                let results = PHAsset.fetchAssetsWithMediaType(.Image, options: options)
                let manager = PHImageManager.defaultManager()
                let option = PHImageRequestOptions()
                option.synchronous = true
                var images = Array<UIImage>()
                
                results.enumerateObjectsUsingBlock { asset, idx, stop in
                    if let asset = asset as? PHAsset where asset.location != nil {
                        if asset.location!.distanceFromLocation(self.locationToDisplay.location) < Double(SettingsController.sharedController.nearbyPhotoRange) {
                            manager.requestImageForAsset(asset, targetSize: CGSize(width: 425.0, height: 425.0), contentMode: .AspectFit, options: option) { image, info in
                                if let img = image {
                                    images.append(img)
                                }
                            }
                        }
                        
                        if images.count > 5 {
                            dispatch_async(dispatch_get_main_queue()) { completion(images) }
                        }
                    }
                }
                
                if images.count > 0 {
                    dispatch_async(dispatch_get_main_queue()) { completion(images) }
                }
                else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.collectionViewHeightConstraint.constant = 45.0
                        self.view.layoutIfNeeded()
                    }
                    dispatch_async(dispatch_get_main_queue()) { completion(nil) }
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.collectionViewHeightConstraint.constant = 45.0
                    self.view.layoutIfNeeded()
                }
                dispatch_async(dispatch_get_main_queue()) { completion(nil) }
            }
        }
    }
    
    private func refreshView()
    {
        title = locationToDisplay.title

        mapView.removeAnnotation(locationToDisplay)
        mapView.addAnnotation(locationToDisplay)
        
        if #available(iOS 9.0, *) {
            mapView.showsCompass = true
            mapView.showsScale = true
        }
        
        if let address = locationToDisplay.placemark {
            addressLabel.attributedText = stringFromAddress(address, withNewLine: true).basicAttributedString()
            coordinateLabel.text = stringFromCoordinate(locationToDisplay.location.coordinate)
        }
        else {
            addressLabel.text = stringFromCoordinate(locationToDisplay.location.coordinate)
            coordinateLabel.text = "No Address Found"
        }
        
        altitudeLabel.text = altitudeString(locationToDisplay.location.altitude)
        dateLabel.text = relativeStringForDate(locationToDisplay.location.timestamp)
        colorView.backgroundColor = locationToDisplay.color ?? UIColor.clearColor()
    }

}


extension LocationDetailViewController: MKMapViewDelegate
{
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation)
    {
        let center = CLLocationCoordinate2D(
            latitude: userLocation.coordinate.latitude - (userLocation.coordinate.latitude - locationToDisplay.location.coordinate.latitude) / 2,
            longitude: userLocation.coordinate.longitude - (userLocation.coordinate.longitude - locationToDisplay.location.coordinate.longitude) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.052125, abs(userLocation.coordinate.latitude - locationToDisplay.location.coordinate.latitude) * 2.5),
            longitudeDelta: max(0.052125, abs(userLocation.coordinate.longitude - locationToDisplay.location.coordinate.longitude) * 2.5)
        )
        let region = MKCoordinateRegionMake(center, span)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        guard annotation is Location else {
            return nil
        }
        
        let reuseIdentifier = "Location"
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier) as! MKPinAnnotationView!
        
        annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        annotationView.enabled = true
        annotationView.canShowCallout = true
        annotationView.animatesDrop = false
        
        if #available(iOS 9.0, *) {
            annotationView.pinTintColor = locationToDisplay.color
        }
        else {
            annotationView.pinColor = .Red
        }
        
        let rightButton = UIButton()
        rightButton.tintColor = locationToDisplay.color
        rightButton.setImage(UIImage(named: "open-location"), forState: .Normal)
        rightButton.sizeToFit()
        rightButton.addTarget(self, action: "annotationButtonPressed", forControlEvents: .TouchUpInside)
        annotationView.rightCalloutAccessoryView = rightButton
        
        return annotationView
    }
    
}


extension LocationDetailViewController: NewLocationViewControllerDelegate
{
    
    func newLocationViewControllerDidEditLocation(editedLocation: Location)
    {
        locationToDisplay = editedLocation
    }
    
}


extension LocationDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource
{
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        guard let photos = nearbyPhotos else {
            fatalError("Should have had photos to display.")
        }
        
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PhotoCell.reuseIdentifer, forIndexPath: indexPath) as? PhotoCell else {
            fatalError("Expected to display a 'PhotoCell'.")
        }
        
        cell.imageView.image = photos[indexPath.item]
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        guard let photos = nearbyPhotos else {
            return
        }
        
        let photoVC = PhotoViewController()
        let image = photos[indexPath.item]
        photoVC.photoToDisplay = image
        presentViewController(photoVC, animated: true, completion: nil)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        if let photos = nearbyPhotos where photos.count > 0 {
            return photos.count
        }
        return 0
    }
    
}
