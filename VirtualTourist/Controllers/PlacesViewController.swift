//
//  PlacesViewController.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/17/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import UIKit
import MapKit

class PlacesViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    var pin: Pin!

    override func viewDidLoad() {
        super.viewDidLoad()

        let tc = tabBarController as! TabBarViewController
        pin = tc.pin
        
        if pin.places.count == 0 {
            getGooglePlaces()
        }
    }
    
    func getGooglePlaces() {
        GooglePlacesClient.sharedInstance().placesSearch(pin) { placesProperties, errorString in
            if errorString != nil {
                
            } else {
                if let placesProperties = placesProperties {
                    for placeProperty in placesProperties {
                        println(placeProperty)
                        let place = Place(placeName: placeProperty["placeName"]!, vicinity: placeProperty["vicinity"]!)
                        self.pin.places.append(place)
                    }
                }
            }
        }
    }

}
