
import UIKit

class LocationCell: UITableViewCell
{
    
    static let cellHeight: CGFloat = 68.0
    static let reuseIdentifier = "LocationCell"
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var createdDateLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var colorCategoryStripView: UIView!
    
    var location: Location? {
        didSet {
            if let locationToDisplay = location, let place = locationToDisplay.placemark {
                addressLabel.text = stringFromAddress(place)
                createdDateLabel.text = relativeStringForDate(locationToDisplay.location.timestamp)
                distanceLabel.text = "todo"
                titleLabel.text = locationToDisplay.title
                colorCategoryStripView.backgroundColor = locationToDisplay.color
            }
        }
    }
    
}
