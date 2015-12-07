
import UIKit


class TextEntryCell: UITableViewCell
{

    static let cellHeight: CGFloat = 44.0
    static let reuseIdentifier = "TextEntryCell"
    
    @IBOutlet var textField: UITextField!
    
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        textField.delegate = self
        textField.tintColor = ColorController.navBarBackgroundColor
    }

}


extension TextEntryCell: UITextFieldDelegate
{
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        return endEditing(true)
    }
    
}
