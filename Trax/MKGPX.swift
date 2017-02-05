//
//  MKGPX.swift
//  Trax
//
//  Created by Chanh Nguyen on 2/5/17.
//  Copyright © 2017 Stanford University. All rights reserved.
//

import MapKit

extension GPX.Waypoint: MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var title: String? {
        return name
    }
    
    var subtitle: String? {
        return info
    }
}
