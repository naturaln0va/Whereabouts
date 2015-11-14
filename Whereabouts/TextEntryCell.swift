
import UIKit


class TextEntryCell: StyledCell
{

    static let cellHeight: CGFloat = 75.0
    static let reuseIdentifier = "TextEntryCell"
    
    @IBOutlet var textField: UITextField!
    
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        textField.delegate = self
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
