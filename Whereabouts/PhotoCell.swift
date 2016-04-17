
import UIKit


class PhotoCell: UICollectionViewCell {
    
    @IBOutlet private var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.alpha = 0
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.alpha = 0
        imageView.image = nil
    }
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes?) {
        layoutIfNeeded()
    }
    
    func setImage(image: UIImage) {
        imageView.image = image
        
        UIView.animateWithDuration(0.25) { [weak self] in
            self?.imageView.alpha = 1
        }
    }
    
}
