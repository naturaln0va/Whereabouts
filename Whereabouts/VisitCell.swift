
import UIKit

class VisitCell: UITableViewCell {

    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    func configureCellWithVisit(visit: Visit) {
        locationLabel.text = visit.title
        detailLabel.text = visit.subtitle
    }
    
}
