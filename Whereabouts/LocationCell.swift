
import UIKit

class LocationCell: UITableViewCell {
    
    static let cellHeight: CGFloat = 68.0
    static let reuseIdentifier = "LocationCell"
    
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var createdDateLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    func configureCellWithLocation(locationToDisplay: Location) {
        distanceLabel.text = ""
        createdDateLabel.text = locationToDisplay.date.relativeString()
        
        if let item = locationToDisplay.mapItem where item.name?.characters.count > 0 {
            if let title = locationToDisplay.locationTitle where title.characters.count > 0 {
                titleLabel.text = title
            }
            else {
                titleLabel.text = item.name
            }
            
            addressLabel.text = item.placemark.partialFormatedString()
        }
        else if let place = locationToDisplay.placemark {
            if let title = locationToDisplay.locationTitle where title.characters.count > 0 {
                titleLabel.text = title
                addressLabel.text = place.partialFormatedString()
            }
            else {
                let addressComps = place.partialFormatedString().componentsSeparatedByString("\n")
                
                if let firstComp = addressComps.first, let lastComp = addressComps.last where addressComps.count == 2 {
                    titleLabel.text = firstComp
                    addressLabel.text = lastComp
                }
                else {
                    titleLabel.text = place.partialFormatedString()
                    addressLabel.text = stringFromCoordinate(locationToDisplay.coordinate)
                }
            }
        }
        else {
            if let title = locationToDisplay.locationTitle where title.characters.count > 0 {
                titleLabel.text = title
                addressLabel.text = stringFromCoordinate(locationToDisplay.location.coordinate)
            }
            else {
                titleLabel.text = stringFromCoordinate(locationToDisplay.location.coordinate)
                addressLabel.text = "No address found."
            }
        }
    }
    
}
