
import UIKit


class PhotoCell: UICollectionViewCell
{

    static let reuseIdentifer: String = "PhotoCell"
    
    @IBOutlet var imageView: UIImageView!
    
    override func prepareForReuse()
    {
        super.prepareForReuse()
        imageView.image = nil
    }
    
}
