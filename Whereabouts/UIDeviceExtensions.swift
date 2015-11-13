//
//  UIDeviceExtensions.swift
//
//  All Purpose UIDevice Extensions for a Swift Project
//
//  Created by Ryan Ackermann on 11/29/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

import UIKit

class RADevice {
    class func getDeviceName() -> String {
        let deviceSize = UIScreen.mainScreen().nativeBounds
        
        switch(deviceSize.width) {
        case 640:
            if deviceSize.height == 960 {
                return "iPhone4"
            } else {
                return "iPhone5"
            }
        case 750:
            return "iPhone6"
        case 1080:
            return "iPhone6+"
        default:
            return "Uknown Device"
        }
    }
}
