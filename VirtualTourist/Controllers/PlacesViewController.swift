//
//  PlacesViewController.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/17/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import UIKit
import MapKit

class PlacesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var pin: Pin!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.stopAnimating()

        let tc = tabBarController as! TabBarViewController
        pin = tc.pin
        
        if pin.places.count == 0 {
            getGooglePlaces()
        }
    }
    
    func getGooglePlaces() {
        activityIndicator.startAnimating()
        GooglePlacesClient.sharedInstance().placesSearch(pin) { placesProperties, errorString in
            if errorString != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator.stopAnimating()
                }
            } else {
                if let placesProperties = placesProperties {
                    for placeProperty in placesProperties {
                        println(placeProperty)
                        let place = Place(placeName: placeProperty["placeName"]!, vicinity: placeProperty["vicinity"]!)
                        self.pin.places.append(place)
                    }
                    dispatch_async(dispatch_get_main_queue()) {
                        self.activityIndicator.stopAnimating()
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    // MARK: - TableView delegates
    
    
    
    // MARK: - TableView data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pin.places.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PlaceCell", forIndexPath: indexPath) as! UITableViewCell
        
        let place = pin.places[indexPath.row]
        
        // Configure the cell...
        
        cell.textLabel?.text = place.placeName
        cell.detailTextLabel?.text = place.vicinity
        
        return cell
    }

}
