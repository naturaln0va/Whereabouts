
import UIKit

protocol ColorSelectionViewControllerDelegate
{
    func colorSelectionViewControllerDidSelectColor(color: UIColor)
}

private let reuseIdentifier = "Cell"


class ColorSelectionViewController: UICollectionViewController
{
    
    private let colors = [
        UIColor(red:0.980,  green:0.863,  blue:0.337, alpha:1),
        UIColor(red:0.976,  green:0.827,  blue:0.024, alpha:1),
        UIColor(red:0.949,  green:0.608,  blue:0.333, alpha:1),
        UIColor(red:0.863,  green:0.490,  blue:0.118, alpha:1),
        UIColor(red:0.957,  green:0.467,  blue:0.435, alpha:1),
        UIColor(red:0.898,  green:0.302,  blue:0.259, alpha:1),
        UIColor(red:0.788,  green:0.816,  blue:0.816, alpha:1),
        UIColor(red:0.584,  green:0.647,  blue:0.651, alpha:1),
        UIColor(red:0.584,  green:0.373,  blue:0.706, alpha:1),
        UIColor(red:0.424,  green:0.290,  blue:0.498, alpha:1),
        UIColor(red:0.875,  green:0.424,  blue:0.714, alpha:1),
        UIColor(red:0.820,  green:0.286,  blue:0.627, alpha:1),
        UIColor(red:0.278,  green:0.710,  blue:0.988, alpha:1),
        UIColor(red:0.192,  green:0.506,  blue:0.718, alpha:1),
        UIColor(red:0.824,  green:0.961,  blue:0.482, alpha:1),
        UIColor(red:0.600,  green:0.816,  blue:0.169, alpha:1),
        UIColor(red:0.373,  green:0.745,  blue:0.541, alpha:1),
        UIColor(red:0.298,  green:0.529,  blue:0.404, alpha:1),
        UIColor(red:0.404,  green:0.816,  blue:0.714, alpha:1),
        UIColor(red:0.224,  green:0.624,  blue:0.525, alpha:1)
    ]
    
    var delegate: ColorSelectionViewControllerDelegate?
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        title = "Select a Color"
        
        collectionView?.backgroundColor = UIColor.whiteColor()
        collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        navigationController?.setToolbarHidden(true, animated: true)
    }

    // MARK: UICollectionViewDataSource
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return colors.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
    
        cell.contentView.backgroundColor = colors[indexPath.item]
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if let delegate = delegate {
            delegate.colorSelectionViewControllerDidSelectColor(colors[indexPath.item])
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
}
