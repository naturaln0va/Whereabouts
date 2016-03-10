
import UIKit


extension String {
    
    func basicAttributedString() -> NSAttributedString {
        let comps = self.componentsSeparatedByString("\n")
        
        if comps.count <= 1 {
            return NSAttributedString(string: self, attributes: [
                NSForegroundColorAttributeName: UIColor.blackColor(),
                NSFontAttributeName: UIFont.systemFontOfSize(20, weight: UIFontWeightMedium)
            ])
        }
        
        let firstPart = comps.first!
        let last = self.substringFromIndex(self.startIndex.advancedBy(firstPart.characters.count + 1))
        
        let mut = NSMutableAttributedString()
        
        mut.appendAttributedString(NSAttributedString(string: firstPart, attributes: [
            NSForegroundColorAttributeName: UIColor.blackColor(),
            NSFontAttributeName: UIFont.systemFontOfSize(20, weight: UIFontWeightMedium)
        ]))
        mut.appendAttributedString(NSAttributedString(string: "\n"))
        mut.appendAttributedString(NSAttributedString(string: last, attributes: [
            NSForegroundColorAttributeName: UIColor(white: 0.5, alpha: 1.0),
            NSFontAttributeName: UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        ]))
        
        return NSAttributedString(attributedString: mut)
    }
    
}