
import UIKit

class LocationCell: UITableViewCell
{
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var createdDateLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var colorCategoryStripView: UIView!
    
    var location: Location? {
        didSet {
            if let loc = location, let place = loc.placemark {
                addressLabel.text = stringFromAddress(place)
                createdDateLabel.text = relativeStringForDate(loc.date)
                distanceLabel.text = "todo"
                titleLabel.text = loc.title
                colorCategoryStripView.backgroundColor = loc.color
            }
        }
    }
}
