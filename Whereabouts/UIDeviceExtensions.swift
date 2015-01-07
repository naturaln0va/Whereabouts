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
    var deviceName: String!
    
    init() {
        let deviceSize = UIScreen.mainScreen().nativeBounds
        
        switch(deviceSize.width) {
        case 640:
            if deviceSize.height == 960 {
                deviceName = "iPhone4"
            } else {
                deviceName = "iPhone5"
            }
        case 750:
            deviceName = "iPhone6"
        case 1242:
            deviceName = "iPhone6+"
        default:
            deviceName = "Uknown Device"
        }
    }
}
