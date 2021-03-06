
import UIKit

@IBDesignable
class PlaceholderTextView: UITextView {
    
    private var shouldDrawPlaceholder = false

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }
    
    private func commonInit() {
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(PlaceholderTextView.textDidChange),
            name: UITextViewTextDidChangeNotification,
            object: nil
        )
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @IBInspectable var placeholder: String = "" {
        didSet {
            refreshView()
        }
    }
    
    override var text: String! {
        didSet {
            refreshView()
        }
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        if shouldDrawPlaceholder {
            let converted = placeholder as NSString
            let attributes: [String: AnyObject] = [NSFontAttributeName: font!, NSForegroundColorAttributeName: UIColor(red: 0.78,  green: 0.78,  blue: 0.80, alpha: 1.0)]
            converted.drawInRect(CGRectInset(bounds, 7, textContainerInset.top), withAttributes: attributes)
        }
    }
    
    // MARK: - Helpers
    
    private func refreshView() {
        let previous = shouldDrawPlaceholder
        shouldDrawPlaceholder = placeholder.characters.count > 0 && text.characters.count == 0
        
        if shouldDrawPlaceholder != previous {
            setNeedsDisplay()
        }
    }
    
    // MARK: - Notification
    
    @objc private func textDidChange() {
        refreshView()
    }

}
