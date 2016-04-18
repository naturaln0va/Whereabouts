
import CoreLocation

extension CLLocation {
    
    func vCardURL() -> NSURL? {
        guard let cachesPathString = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first else {
            print("Error: couldn't find the caches directory.")
            return nil
        }
        
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            print("Error: the supplied coordinate, \(coordinate), is not valid.")
            return nil
        }
        
        let vCardString = [
            "BEGIN:VCARD",
            "VERSION:3.0",
            "PRODID:-//Apple Inc.//iOS 9.3.1//EN",
            "N:;Shared Location;;;",
            "FN:Shared Location",
            "item1.URL;type=pref:http://maps.apple.com/?address=&ll=\(coordinate.latitude)\\,\(coordinate.longitude)&q=\(coordinate.latitude)\\,\(coordinate.longitude)&t=m",
            "item1.X-ABLabel:map url",
            "END:VCARD"
        ].joinWithSeparator("\n")
        
        let vCardFilePath = (cachesPathString as NSString).stringByAppendingPathComponent("vCard.loc.vcf")
        
        do {
            try vCardString.writeToFile(vCardFilePath, atomically: true, encoding: NSUTF8StringEncoding)
        }
        catch let error {
            print("Error, \(error), saving vCard: \(vCardString) to file path: \(vCardFilePath).")
        }
        
        return NSURL(fileURLWithPath: vCardFilePath)
    }
    
}
