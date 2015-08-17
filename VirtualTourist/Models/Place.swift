//
//  Place.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/17/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import Foundation

class Place {
    var placeName: String
    var vicinity: String
    
    init(placeName: String, vicinity: String) {
        self.placeName = placeName
        self.vicinity = vicinity
    }
}