
import UIKit

class LocationCell: UITableViewCell {
    
    static let cellHeight: CGFloat = 68.0
    static let reuseIdentifier = "LocationCell"
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var createdDateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var colorCategoryStripView: UIView!
    
    func configureCell(locationToDisplay: Location) {
        colorCategoryStripView.backgroundColor = locationToDisplay.color
        createdDateLabel.text = locationToDisplay.date.relativeString()
        
        if let item = locationToDisplay.mapItem where item.name?.characters.count > 0 {
            titleLabel.text = item.name
            addressLabel.text = item.placemark.fullFormatedString()
        }
        else if let place = locationToDisplay.placemark {
            let addressComps = stringFromAddress(place, withNewLine: true).componentsSeparatedByString("\n")
            
            if let firstComp = addressComps.first, let lastComp = addressComps.last where addressComps.count == 2 {
                titleLabel.text = firstComp
                addressLabel.text = lastComp
            }
            else {
                titleLabel.text = stringFromAddress(place, withNewLine: false)
                addressLabel.text = stringFromCoordinate(locationToDisplay.coordinate)
            }
        }
        else {
            titleLabel.text = stringFromCoordinate(locationToDisplay.location.coordinate)
            addressLabel.text = "No address found."
        }
    }
    
}
