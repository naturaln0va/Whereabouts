
import CoreLocation

extension CLPlacemark {
    
    func fullFormatedString() -> String {
        var line1 = ""
        var line2 = ""
        var line3 = ""
        
        if let s = self.subThoroughfare {
            line1 += s + " "
        }
        
        if let s = self.thoroughfare {
            line1 += s
        }
        
        if let s = self.locality {
            line2 += s + " "
        }
        
        if let s = self.administrativeArea {
            line2 += s + " "
        }
        
        if let s = self.postalCode {
            line2 += s
        }
        
        if let s = self.country {
            line3 = s
        }
        
        if line1.characters.count > 0 && line2.characters.count > 0 && line3.characters.count > 0 {
            return [line1, line2, line3].joinWithSeparator("\n")
        }
        else if line1.characters.count > 0 && line2.characters.count > 0 {
            return [line1, line2].joinWithSeparator("\n")
        }
        else if line1.characters.count > 0 {
            return line1
        }
        else if line2.characters.count > 0 {
            return line2
        }
        else {
            return "Invalid Address"
        }
    }
    
    func partialFormatedString() -> String {
        var line1 = ""
        var line2 = ""
        
        if let s = self.subThoroughfare {
            line1 += s + " "
        }
        
        if let s = self.thoroughfare {
            line1 += s
        }
        
        if let s = self.locality {
            line2 += s + " "
        }
        
        if let s = self.administrativeArea {
            line2 += s + " "
        }
        
        if let s = self.postalCode {
            line2 += s
        }
        
        if line1.characters.count > 0 && line2.characters.count > 0 {
            return [line1, line2].joinWithSeparator("\n")
        }
        else if line1.characters.count > 0 {
            return line1
        }
        else if line2.characters.count > 0 {
            return line2
        }
        else {
            return "Invalid Address"
        }
    }
    
}
