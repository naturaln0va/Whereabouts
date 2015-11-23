
import UIKit


class TextEntryCell: StyledCell
{

    static let cellHeight: CGFloat = 67.0
    static let reuseIdentifier = "TextEntryCell"
    
    @IBOutlet var textField: UITextField!
    
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        textField.delegate = self
        textField.tintColor = ColorController.navBarBackgroundColor
    }
    
    override func drawRect(rect: CGRect)
    {
        UIColor.whiteColor().set()
        UIRectFill(rect)
        
        let ctx = UIGraphicsGetCurrentContext()!
        CGContextSetStrokeColorWithColor(ctx, ColorController.backgroundColor.CGColor)
        
        let path = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, 0, CGRectGetMaxY(rect))
        CGPathAddLineToPoint(path, nil, CGRectGetMaxX(rect), CGRectGetMaxY(rect))
        
        CGContextAddPath(ctx, path)
        CGContextSetLineWidth(ctx, 2)
        CGContextDrawPath(ctx, .Stroke)
    }

}


extension TextEntryCell: UITextFieldDelegate
{
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        endEditing(true)
        return true
    }
    
}
