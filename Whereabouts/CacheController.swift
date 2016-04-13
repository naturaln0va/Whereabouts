
import UIKit

class CacheController {
    
    private static let cachesDirectory = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first! as NSString
    
    static func cacheImageWithIdentifier(image: UIImage, identifier: String) {
        UIImagePNGRepresentation(image)?.writeToFile(cachesDirectory.stringByAppendingPathComponent(identifier), atomically: true)
    }
    
    static func imageForIdentifier(identifier: String) -> UIImage? {
        if let imageData = NSData(contentsOfFile: cachesDirectory.stringByAppendingPathComponent(identifier)) {
            return UIImage(data: imageData)
        }
        else {
            return nil
        }
    }
    
}