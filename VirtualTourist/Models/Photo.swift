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
    
    var imageFetchInProgress: Bool = false
    
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
    
    func fetchImageData(completionHandler: (data: NSData?, error: NSError?) -> Void) {
        if imageFetchInProgress == false {
            imageFetchInProgress = true
            if let url = NSURL(string: remotePath) {
                NSURLSession.sharedSession().dataTaskWithURL(url) { data, response, error in
                    if error != nil {
                        completionHandler(data: nil, error: error)
                    } else {
                        NSFileManager.defaultManager().createFileAtPath(self.localURL.path!, contents: data, attributes: nil)
                        self.imageFetchInProgress = false
                        completionHandler(data: data, error: nil)
                    }
                }.resume()
            }
        }
    }
    
    deinit {
        if NSFileManager.defaultManager().fileExistsAtPath(localURL.path!) {
            var error: NSError? = nil
            NSFileManager.defaultManager().removeItemAtURL(localURL, error: &error)
            if error != nil {
                println("couldn't remove image: \(imageName)")
            } else {
                println("removed image: \(imageName)")
            }
        }
    }
}