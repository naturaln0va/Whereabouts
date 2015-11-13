//
//  Created by Ryan Ackermann on 5/30/15.
//  Copyright (c) 2015 Ryan Ackermann. All rights reserved.
//

import MapKit

class RHACurrentLocationAnnotation: NSObject, MKAnnotation {
    
    private var latitude: CLLocationDegrees!
    private var longitude: CLLocationDegrees!
    
    convenience init(latitude: CLLocationDegrees, longitude: CLLocationDegrees)
    {
        self.init()
        self.latitude = latitude
        self.longitude = longitude
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    var title: String? {
        return "Current Location"
    }
    
    var subtitle: String? {
        return stringFromCoordinate(coordinate)
    }
}
