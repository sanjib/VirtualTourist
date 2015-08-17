//
//  Photo.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/17/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import Foundation

class Photo {
    var imageName: String
    var remotePath: String
    
    init(imageName: String, remotePath: String) {
        self.imageName = imageName
        self.remotePath = remotePath
    }
}