
import UIKit
import Photos

class PhotosViewController: UICollectionViewController {
    
    private let expanded: Bool
    private let assetsToDisplay: [PHAsset]
    private let manager = PHImageManager.defaultManager()
    private let cache = NSCache()
    
    private lazy var imageRequestOptions: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.networkAccessAllowed = !NSProcessInfo.processInfo().lowPowerModeEnabled
        options.synchronous = false
        return options
    }()
    
    init(assets: [PHAsset], expanded: Bool) {
        self.expanded = expanded
        assetsToDisplay = assets
        
        let layout = GridLayout()
        layout.numberOfItemsPerRow = expanded ? 1 : 3
        
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = expanded ? "Expanded" : "Photos"
        view.backgroundColor = UIColor.blackColor()

        collectionView?.registerNib(UINib(nibName: String(PhotoCell), bundle: nil), forCellWithReuseIdentifier: String(PhotoCell))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.toolbarHidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setToolbarHidden(false, animated: true)
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return assetsToDisplay.count > 0 ? 1 : 0
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assetsToDisplay.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier(String(PhotoCell), forIndexPath: indexPath) as? PhotoCell else {
            fatalError("Expected to display a cell of type 'PhotoCell'.")
        }
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? PhotoCell else {
            fatalError("CollectionView cell should be of type 'PhotoCell'.")
        }
        
        let asset = assetsToDisplay[indexPath.item]
        let imageSize = cell.bounds.width
        
        if let cachedImage = cache.objectForKey(indexPath.item) as? UIImage {
            if cachedImage.size.width == imageSize {
                cell.setImage(cachedImage)
                return
            }
            else {
                cache.removeObjectForKey(indexPath.item)
            }
        }
        
        manager.requestImageForAsset(asset, targetSize: CGSize(width: imageSize, height: imageSize), contentMode: .AspectFill, options: imageRequestOptions) { [weak self] image, info in
            if let img = image {
                self?.cache.setObject(img, forKey: indexPath.item)
                cell.setImage(img)
            }
            else {
                print("Error fetching image for asset: \(asset).")
            }
        }
    }
    
    // MARK: - UICollectionViewDelegate
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if expanded {
            return
        }
        
        let vc = PhotosViewController(assets: assetsToDisplay, expanded: true)
        vc.useLayoutToLayoutNavigationTransitions = true
        
        navigationController?.pushViewController(vc, animated: true)
    }

}
