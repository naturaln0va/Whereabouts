
import UIKit

protocol ColorSelectionViewControllerDelegate
{
    func colorSelectionViewControllerDidSelectColor(color: UIColor)
}

private let reuseIdentifier = "Cell"


class ColorSelectionViewController: UICollectionViewController
{
    
    private let colors = [
        UIColor(hue:0.467, saturation:0.862, brightness:0.737, alpha:1),
        UIColor(hue:0.467, saturation:0.856, brightness:0.627, alpha:1),
        UIColor(hue:0.404, saturation:0.775, brightness:0.800, alpha:1),
        UIColor(hue:0.404, saturation:0.776, brightness:0.682, alpha:1),
        UIColor(hue:0.567, saturation:0.763, brightness:0.859, alpha:1),
        UIColor(hue:0.566, saturation:0.778, brightness:0.725, alpha:1),
        UIColor(hue:0.785, saturation:0.511, brightness:0.714, alpha:1),
        UIColor(hue:0.784, saturation:0.607, brightness:0.678, alpha:1),
        UIColor(hue:0.134, saturation:0.942, brightness:0.945, alpha:1),
        UIColor(hue:0.102, saturation:0.926, brightness:0.953, alpha:1),
        UIColor(hue:0.079, saturation:0.857, brightness:0.902, alpha:1),
        UIColor(hue:0.066, saturation:1, brightness:0.827, alpha:1),
        UIColor(hue:0.016, saturation:0.740, brightness:0.906, alpha:1),
        UIColor(hue:0.016, saturation:0.776, brightness:0.753, alpha:1),
        UIColor(hue:0.583, saturation:0.447, brightness:0.369, alpha:1),
        UIColor(hue:0.583, saturation:0.450, brightness:0.314, alpha:1),
        UIColor(hue:0.510, saturation:0.102, brightness:0.651, alpha:1),
        UIColor(hue:0.512, saturation:0.099, brightness:0.553, alpha:1),
        UIColor(hue:0.533, saturation:0.021, brightness:0.945, alpha:1),
        UIColor(hue:0.567, saturation:0.050, brightness:0.780, alpha:1)
    ]
    
    var delegate: ColorSelectionViewControllerDelegate?
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        title = "Select a Color"
        collectionView?.backgroundColor = UIColor.whiteColor()

        collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
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
