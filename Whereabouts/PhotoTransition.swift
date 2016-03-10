
import UIKit


class PhotoTransition: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    
    var transitionDuration: Double!
    
    init(duration: Double) {
        super.init()
        transitionDuration = duration
    }

    // MARK: - UIViewControllerAnimatedTransitioning
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return transitionDuration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
            let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) else {
                print("Could not parse the to and/or from view controllers from the context.")
                return
        }
        
        if let containerView = transitionContext.containerView() {
            let finalFrameForVC = transitionContext.finalFrameForViewController(toVC)
            toVC.view.alpha = 0.0
            containerView.addSubview(toVC.view)
            
            UIView.animateWithDuration(transitionDuration(transitionContext), animations: {
                fromVC.view.alpha = 0.125
                toVC.view.alpha = 1.0
                toVC.view.frame = finalFrameForVC
            }, completion: { _ in
                transitionContext.completeTransition(true)
            })
        }
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
}