//
//  Photo.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/17/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@objc(Photo)

class Photo: NSManagedObject {
    @NSManaged var imageName: String
    @NSManaged var remotePath: String
    @NSManaged var pin: Pin?
    
    var imageFetchInProgress: Bool = false
    private let noPhotoAvailableImageData = NSData(data: UIImagePNGRepresentation(UIImage(named: "noPhotoAvailable")))
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(imageName: String, remotePath: String, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.imageName = imageName
        self.remotePath = remotePath
    }
    
    var localURL: NSURL {
        let url = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent(imageName)
    }
    
    var imageData: NSData? {
        var imageData: NSData? = nil
        if NSFileManager.defaultManager().fileExistsAtPath(localURL.path!) {
            imageData = NSData(contentsOfURL: localURL)
        }
        return imageData
    }
    
    func fetchImageData(completionHandler: () -> Void) {
        if imageFetchInProgress == false {
            var localURL = self.localURL
            imageFetchInProgress = true
            if let url = NSURL(string: remotePath) {
                NSURLSession.sharedSession().dataTaskWithURL(url) { data, response, error in
                    if error != nil {
                        NSFileManager.defaultManager().createFileAtPath(self.localURL.path!, contents: self.noPhotoAvailableImageData, attributes: nil)
                        self.imageFetchInProgress = false
                    } else {
                        NSFileManager.defaultManager().createFileAtPath(self.localURL.path!, contents: data, attributes: nil)
                        self.imageFetchInProgress = false
                    }
                    completionHandler()
                }.resume()
            }
        }
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        if NSFileManager.defaultManager().fileExistsAtPath(localURL.path!) {
            var error: NSError? = nil
            NSFileManager.defaultManager().removeItemAtURL(localURL, error: &error)
            if error != nil {
                println("couldn't remove image at: \(imageName)")
            } else {
                println("removed image at: \(imageName)")
            }
        }
    }
    
//    deinit {
//        var localURL = self.localURL
//        if localURL == nil {
//            localURL = getLocalURL()
//        }
//        
//        if NSFileManager.defaultManager().fileExistsAtPath(localURL!.path!) {
//            var error: NSError? = nil
//            NSFileManager.defaultManager().removeItemAtURL(localURL!, error: &error)
//            if error != nil {
//                println("couldn't remove image at: \(localURL!.path!)")
//            } else {
//                println("removed image at: \(localURL!.path!)")
//            }
//        }
//    }
}