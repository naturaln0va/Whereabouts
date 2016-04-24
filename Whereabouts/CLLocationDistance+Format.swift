
import MapKit

extension CLLocationDistance {
    
    func formattedString() -> String {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .Abbreviated
        
        var usesMetric = false
        if let currentLocaleUsesMetric = NSLocale.currentLocale().objectForKey(NSLocaleUsesMetricSystem) as? NSNumber {
            usesMetric = currentLocaleUsesMetric.boolValue
        }
        
        var distanceString = ""
        if !usesMetric {
            let distInFeet = Int(self * 3.2808399)
            distanceString = distInFeet >= 5280 ? formatter.stringFromDistance(self) : "\(distInFeet)ft"
        }
        else {
            distanceString = self >= 1000 ? formatter.stringFromDistance(self) : "\(Int(self))m"
        }
        
        return distanceString
    }
    
}