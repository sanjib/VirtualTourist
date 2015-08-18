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
    @IBOutlet weak var noPlacesFoundLabel: UILabel!
    
    var pin: Pin!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.userInteractionEnabled = false
        tableView.delegate = self
        tableView.dataSource = self
        activityIndicator.hidesWhenStopped = true
        noPlacesFoundLabel.hidden = true
        activityIndicator.stopAnimating()

        let tc = tabBarController as! TabBarViewController
        pin = tc.pin
        
        if pin.places.count == 0 {
            getGooglePlaces()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.title = "Places"
        
        let region = MKCoordinateRegionMakeWithDistance(pin.coordinate, 100_000, 100_000)
        mapView.setRegion(region, animated: false)
        mapView.addAnnotation(pin)
    }
    
    func getGooglePlaces() {
        activityIndicator.startAnimating()
        noPlacesFoundLabel.hidden = true
        
        GooglePlacesClient.sharedInstance().placesSearch(pin) { placesProperties, errorString in
            if errorString != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator.stopAnimating()
                    self.noPlacesFoundLabel.hidden = false
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
