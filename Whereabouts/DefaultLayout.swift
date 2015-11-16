
import UIKit


class DefaultLayout: UICollectionViewFlowLayout
{
    
    private var itemsPerRow: Int = 2
    
    
    override func prepareLayout()
    {
        sectionInset = UIEdgeInsetsMake(20, 20, 20, 20)
        
        let collectionViewWidth = collectionView?.bounds.size.width
        
        let leftRightSpacing = sectionInset.left + sectionInset.right
        
        let totalInterItemSpacing: CGFloat
        
        switch self.itemsPerRow {
        case 1:
            totalInterItemSpacing = CGFloat(0)
        default:
            totalInterItemSpacing = CGFloat(itemsPerRow - 1) * (minimumInteritemSpacing * 2)
        }
        
        let itemWidth : CGFloat
        
        switch self.itemsPerRow {
        case 1:
            itemWidth = collectionViewWidth! - leftRightSpacing
        default:
            itemWidth = floor((collectionViewWidth! - totalInterItemSpacing - leftRightSpacing) / CGFloat(itemsPerRow))
        }
        
        itemSize = CGSizeMake(itemWidth, itemWidth)
        minimumLineSpacing = 20.0
    }
    
}