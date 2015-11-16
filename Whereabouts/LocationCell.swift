
import UIKit

class LocationCell: StyledCell
{
    
    static let cellHeight: CGFloat = 68.0
    static let reuseIdentifier = "LocationCell"
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var createdDateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var colorCategoryStripView: UIView!
    
    var location: Location? {
        didSet {
            guard let locationToDisplay = location else {
                return
            }
            
            colorCategoryStripView.backgroundColor = locationToDisplay.color
            createdDateLabel.text = relativeStringForDate(locationToDisplay.location.timestamp)
            titleLabel.text = locationToDisplay.title
            
            if let place = locationToDisplay.placemark {
                addressLabel.text = stringFromAddress(place, withNewLine: false)
            }
            else {
                addressLabel.text = stringFromCoordinate(locationToDisplay.location.coordinate)
            }
            
        }
    }
    
}
