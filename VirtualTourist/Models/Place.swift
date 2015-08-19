//
//  Place.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/17/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import Foundation
import CoreData

@objc(Place)

class Place: NSManagedObject {
    @NSManaged var placeName: String
    @NSManaged var vicinity: String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(placeName: String, vicinity: String, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Place", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.placeName = placeName
        self.vicinity = vicinity
    }
}