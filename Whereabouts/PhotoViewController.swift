
import UIKit

class PhotoViewController: UIViewController {

    var firstLoad = true
    var scrollView: UIScrollView!
    var imageView: UIImageView!
    
    var photoToDisplay: UIImage!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.blackColor()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if firstLoad {
            firstLoad = false
            
            scrollView = UIScrollView(frame: view.bounds)
            scrollView.delegate = self
            view.addSubview(scrollView)
            
            loadImageView()
        }
    }
    
    // MARK: - Helpers
    func loadImageView() {
        imageView = UIImageView(image: photoToDisplay)
        imageView.userInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(PhotoViewController.imageTapped)))
        imageView.frame = CGRect(origin: CGPoint.zero, size: photoToDisplay.size)
        scrollView.addSubview(imageView)
        scrollView.contentSize = photoToDisplay.size
        
        let scrollViewFrame = scrollView.frame
        let scaleWidth = scrollViewFrame.size.width / scrollView.contentSize.width
        let scaleHeight = scrollViewFrame.size.height / scrollView.contentSize.height
        let minScale = min(scaleWidth, scaleHeight)
        
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = 1.0
        scrollView.zoomScale = minScale
        
        centerScrollViewContents()
    }
    
    func centerScrollViewContents() {
        let boundsSize = scrollView.bounds.size
        var contentsFrame = imageView.frame
        
        if contentsFrame.size.width < boundsSize.width {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
            contentsFrame.origin.x = 0.0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            contentsFrame.origin.y = 0.0
        }
        
        imageView.frame = contentsFrame
    }
    
    func imageTapped() {
        dismissViewControllerAnimated(true, completion: nil)
    }

}

extension PhotoViewController: UIScrollViewDelegate {
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        centerScrollViewContents()
    }
    
}
