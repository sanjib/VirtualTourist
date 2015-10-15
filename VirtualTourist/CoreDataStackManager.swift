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

    static let sharedInstance = CoreDataStackManager()
    
    lazy var applicationDocumentDirectory: NSURL = {
        let url = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first!
        return url
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentDirectory.URLByAppendingPathComponent(SQLITE_FILE_NAME)
        
        do {
           try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            NSLog("CoreDataStackManager persistentStoreCoordinator error \(error)")
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
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    NSLog("CoreDataStackManager saveContext error \(error)")
                    abort()
                }
            }
        }
    }
}