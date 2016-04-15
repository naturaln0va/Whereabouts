
import UIKit
import MapKit

class MapItemCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    static let cellHeight: CGFloat = 56.0
    
    func configureWithMapItem(item: MKMapItem) {
        nameLabel.text = item.name
        
        let mut = NSMutableAttributedString()
        
        if let phoneNumber = item.phoneNumber {
            mut.appendAttributedString(NSAttributedString(string: "Phone\n", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(13, weight: UIFontWeightMedium)]))
            mut.appendAttributedString(NSAttributedString(string: phoneNumber))
        }
        
        if let urlString = item.url?.absoluteString {
            if mut.length > 0 {
                mut.appendAttributedString(NSAttributedString(string: "\n\n"))
            }
            
            mut.appendAttributedString(NSAttributedString(string: "Homepage\n", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(13, weight: UIFontWeightMedium)]))
            mut.appendAttributedString(NSAttributedString(string: urlString))
        }
        
        if mut.length > 0 {
            detailLabel.attributedText = mut
        }
    }
    
}
