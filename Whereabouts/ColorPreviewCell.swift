
import UIKit


class ColorPreviewCell: UITableViewCell {

    static let cellHeight: CGFloat = 44.0
    
    @IBOutlet var mainTextLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var colorPreView: UIView!
    
    var colorToDisplay: UIColor? {
        didSet {
            if let color = colorToDisplay {
                colorPreView.backgroundColor = color
                colorPreView.alpha = 1.0
                infoLabel.alpha = 0.0
            }
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        colorPreView.layer.cornerRadius = 15
        colorPreView.alpha = 0.0
        infoLabel.alpha = 1.0
    }

}
