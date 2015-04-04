//
//  UtilExtensions.swift
//
//  All Purpose Extensions for a Swift Project
//
//  Created by Ryan Ackermann on 10/20/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hex & 0xFF00) >> 8) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red:red, green:green, blue:blue, alpha:alpha);
    }
    
    class func turquoiseColor() -> UIColor {
        return UIColor(hex: 0x1abc9c)
    }
    
    class func emeraldColor() -> UIColor {
        return UIColor(hex: 0x2ecc71)
    }
    
    class func peterRiverColor() -> UIColor {
        return UIColor(hex: 0x3498db)
    }
    
    class func amethystColor() -> UIColor {
        return UIColor(hex: 0x9b59b6)
    }
    
    class func wetAsphaltColor() -> UIColor {
        return UIColor(hex: 0x34495e)
    }
    
    class func alizarinColor() -> UIColor {
        return UIColor(hex: 0xe74c3c)
    }
}

func isLightColor(color: UIColor) -> Bool {
    var white: CGFloat?
    color.getWhite(&white!, alpha: nil)
    return (white >= 0.5)
}
