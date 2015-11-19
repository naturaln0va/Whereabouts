
import UIKit


class PhotoViewController: StyledViewController
{

    @IBOutlet var imageView: UIImageView!
    
    var fromImageView: UIImageView?
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


extension PhotoViewController: UIViewControllerAnimatedTransitioning
{
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval
    {
        return 0.5
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning)
    {
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
        
        let containerView = transitionContext.containerView()
        let duration = transitionDuration(transitionContext)
        
    }
    
}
