
import UIKit
import CloudKit

struct CloudLocation {
    
    let color: UIColor
    
    init(record: CKRecord) {
        color = record["color"] as! UIColor
    }
    
}
