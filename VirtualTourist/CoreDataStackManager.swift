//
//  CoreDataStackManager.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/18/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import Foundation
import CoreData

let SQLITE_FILE_NAME = "VirtualTourist.sqlite"

class CoreDataStackManager {
    class func sharedInstance() -> CoreDataStackManager {
        struct Shared {
            static let instance = CoreDataStackManager()
        }
        return Shared.instance
    }
    
    lazy var applicationDocumentDirectory: NSURL = {
        let url = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first as! NSURL
        println(url.path!)
        return url
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentDirectory.URLByAppendingPathComponent(SQLITE_FILE_NAME)
        
        var error: NSError? = nil
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to init perisistent coordinator"
            dict[NSLocalizedFailureReasonErrorKey] = "There was an error adding a persistent store type"
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "VirtualTourist", code: 9999, userInfo: dict as [NSObject:AnyObject])
            NSLog("CoreDataStackManager persistentStoreCoordinator error \(error), \(error?.userInfo)")
            abort()
        }
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        let persistentStoreCoordinator = self.persistentStoreCoordinator
        if persistentStoreCoordinator == nil {
            return nil
        }
        let managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        return managedObjectContext
    }()
    
    func saveContext() {
        if let context = self.managedObjectContext {
            var error: NSError? = nil
            if context.hasChanges && !context.save(&error) {
                NSLog("CoreDataStackManager saveContext error \(error), \(error?.userInfo)")
                abort()
            }
        }
    }
}