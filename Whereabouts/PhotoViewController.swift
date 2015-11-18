
import UIKit


class PhotoViewController: StyledViewController
{

    @IBOutlet var imageView: UIImageView!
    var photoToDisplay: UIImage?
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        imageView.image = photoToDisplay
    }
    
    override func prefersStatusBarHidden() -> Bool
    {
        return true
    }
    
    // MARK: - Touches
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        super.touchesBegan(touches, withEvent: event)
        dismissViewControllerAnimated(true, completion: nil)
    }

}
