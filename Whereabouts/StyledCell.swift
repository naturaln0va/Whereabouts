
import UIKit


class StyledCell: UITableViewCell
{
    
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