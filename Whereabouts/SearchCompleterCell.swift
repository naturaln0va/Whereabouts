
import UIKit
import MapKit

@available(iOS 9.3, *)
class SearchCompleterCell: UITableViewCell {

    static let cellHeight: CGFloat = 56.0

    @IBOutlet private weak var mainTextLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        mainTextLabel.text = ""
    }
    
    func configureCellWithResult(result: MKLocalSearchCompletion?) {
        guard let completionResult = result else {
            return
        }
        
        let titleAttrText = NSMutableAttributedString(string: completionResult.title)
        
        for range in completionResult.titleHighlightRanges {
            titleAttrText.addAttributes(
                [NSBackgroundColorAttributeName: UIColor(red: 0.95,  green: 0.77,  blue: 0.05, alpha: 0.50)],
                range: range.rangeValue
            )
        }
        
        let subtitleAttrText = NSMutableAttributedString(string: completionResult.subtitle)
        subtitleAttrText.addAttributes([NSFontAttributeName: UIFont.systemFontOfSize(14), NSForegroundColorAttributeName: UIColor.darkGrayColor()], range: NSRange(location: 0, length: subtitleAttrText.length))
        
        for range in completionResult.subtitleHighlightRanges {
            subtitleAttrText.addAttributes(
                [NSBackgroundColorAttributeName: UIColor(red: 0.95,  green: 0.77,  blue: 0.05, alpha: 0.50)],
                range: range.rangeValue
            )
        }
        
        if subtitleAttrText.length > 0 {
            titleAttrText.appendAttributedString(NSAttributedString(string: "\n"))
            titleAttrText.appendAttributedString(subtitleAttrText)
        }
        
        mainTextLabel.attributedText = NSAttributedString(attributedString: titleAttrText)
    }
}
