
import UIKit

class GridLayout: UICollectionViewFlowLayout {
    
    var numberOfItemsPerRow: Int = 3 {
        didSet {
            invalidateLayout()
        }
    }
    
    override func prepareLayout() {
        super.prepareLayout()
        
        guard let collectionView = collectionView else {
            fatalError("ERROR: CollectionView was nil when attemping to prepare the layout.")
        }
        
        minimumLineSpacing = 2
        minimumInteritemSpacing = 2
        
        var newItemSize = itemSize
        
        let itemsPerRow = CGFloat(max(numberOfItemsPerRow, 1))
        
        let totalSpacing = minimumInteritemSpacing * (itemsPerRow - 1.0)
        
        newItemSize.width = (collectionView.bounds.size.width - totalSpacing) / itemsPerRow
        
        if itemSize.height > 0 {
            let itemAspectRatio = itemSize.width / itemSize.height
            newItemSize.height = newItemSize.width / itemAspectRatio
        }
        
        itemSize = newItemSize
    }
    
}
