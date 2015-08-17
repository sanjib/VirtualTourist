//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/17/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import UIKit

class PhotoAlbumViewController: UIViewController {

    var pin: Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tc = tabBarController as! TabBarViewController
        pin = tc.pin

        getFlickrPhotos()
    }
    
    func getFlickrPhotos() {
        FlickrClient.sharedInstance().photosSearch(pin) { photoProperties, errorString in
            if errorString != nil {
                
            } else {
                if let photoProperties = photoProperties {
                    for photoProperty in photoProperties {
                        println(photoProperty)
                    }
                }
            }
        }
    }

}
