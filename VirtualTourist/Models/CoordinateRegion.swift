//
//  CoordinateRegion.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/18/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import Foundation
import MapKit

/*
 * This class is used for creating a NSKeyedArchiver
 * to store the last user viewed mapView region
 */

class CoordinateRegion: NSObject, NSCoding {
    var currentRegion: MKCoordinateRegion
    
    init(region: MKCoordinateRegion) {
        currentRegion = region
    }
    
    required init(coder aDecoder: NSCoder) {
        let latitude = aDecoder.decodeObjectForKey("latitude") as! CLLocationDegrees
        let longitude = aDecoder.decodeObjectForKey("longitude") as! CLLocationDegrees
        let latitudeDelta = aDecoder.decodeObjectForKey("latitudeDelta") as! CLLocationDegrees
        let longitudeDelta = aDecoder.decodeObjectForKey("longitudeDelta") as! CLLocationDegrees
        currentRegion = MKCoordinateRegion(center: CLLocationCoordinate2DMake(latitude, longitude), span: MKCoordinateSpanMake(latitudeDelta, longitudeDelta))
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(currentRegion.center.latitude, forKey: "latitude")
        aCoder.encodeObject(currentRegion.center.longitude, forKey: "longitude")
        aCoder.encodeObject(currentRegion.span.latitudeDelta, forKey: "latitudeDelta")
        aCoder.encodeObject(currentRegion.span.longitudeDelta, forKey: "longitudeDelta")
    }
}