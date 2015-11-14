//
//  Created by Ryan Ackermann on 10/20/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

import UIKit
import CoreLocation

func delay(delay:Double, closure:()->())
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))),
        dispatch_get_main_queue(), closure)
}

extension NSObject
{
    
    var classNameString: String {
        return NSStringFromClass(self.dynamicType).componentsSeparatedByString(".").last!
    }
    
}

extension CLLocation
{
    
    func stringByDistanceFromLocation(toLocation: CLLocation) -> String
    {
        let distance: CLLocationDistance = self.distanceFromLocation(toLocation)
        let roundedDistance = distance / 1609.34
        return "\(roundedDistance.roundTo(2))"
    }
    
}

extension Double
{
    
    func roundTo(places: Int) -> Double
    {
        let divisor = pow(10.0, Double(places))
        return round(self * divisor) / divisor
    }
    
}

extension UIView
{
    
    func snapshot() -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.mainScreen().scale)
        
        drawViewHierarchyInRect(self.bounds, afterScreenUpdates: true)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
}

extension UIImage
{
    
    func imageByScalingToFactor(byFactor: Float) -> UIImage
    {
        let size = CGSizeApplyAffineTransform(self.size, CGAffineTransformMakeScale(CGFloat(byFactor), CGFloat(byFactor)))
        let hasAlpha = true
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        self.drawInRect(CGRect(origin: CGPointZero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func imageByTintingToColor(color: UIColor) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)
        color.setFill()
        let bounds = CGRectMake(0.0, 0.0, self.size.width, self.size.height)
        
        UIRectFill(bounds)
        self.drawInRect(bounds, blendMode: CGBlendMode.DestinationIn, alpha: 1.0)
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return tintedImage
    }
    
}

extension UIColor
{
    
    convenience init(hex: Int, alpha: CGFloat = 1.0)
    {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hex & 0xFF00) >> 8) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red:red, green:green, blue:blue, alpha:alpha);
    }
    
    class func randomColor(alpha: CGFloat = 1.0) -> UIColor
    {
        let randRed = CGFloat(drand48())
        let randBlue = CGFloat(drand48())
        let randGreen = CGFloat(drand48())
        return UIColor(red: randRed, green: randGreen, blue: randBlue, alpha: alpha)
    }
    
    class func turquoiseColor() -> UIColor
    {
        return UIColor(hex: 0x1abc9c)
    }
    
    class func emeraldColor() -> UIColor
    {
        return UIColor(hex: 0x2ecc71)
    }
    
    class func peterRiverColor() -> UIColor
    {
        return UIColor(hex: 0x3498db)
    }
    
    class func amethystColor() -> UIColor
    {
        return UIColor(hex: 0x9b59b6)
    }
    
    class func wetAsphaltColor() -> UIColor
    {
        return UIColor(hex: 0x34495e)
    }
    
    class func alizarinColor() -> UIColor
    {
        return UIColor(hex: 0xe74c3c)
    }
    
    func isLightColor() -> Bool
    {
        var white = CGFloat()
        self.getWhite(&white, alpha: nil)
        return (white >= 0.5)
    }
    
}
