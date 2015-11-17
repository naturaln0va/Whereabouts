
import UIKit


class PhotosLayout: UICollectionViewFlowLayout
{
    
    override func prepareLayout()
    {
        sectionInset = UIEdgeInsetsMake(5, 5, 5, 5)
        
        let size = (collectionView?.bounds.size.height)! - 10.0
        itemSize = CGSizeMake(size, size)
        minimumLineSpacing = 5.0
        scrollDirection = .Horizontal
    }
    
}