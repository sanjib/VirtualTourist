//
//  PlacesViewController.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/17/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PlacesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noPlacesFoundLabel: UILabel!
    
    var pin: Pin!

    // MARK: - View lifecycle
    
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
        
//        if pin.places.count == 0 {
//            getGooglePlaces()
//        }
        
        // CoreData
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(nil)
        
        if fetchedResultsController.fetchedObjects?.count == 0 {
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
    
    // MARK: - CoreData
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Place")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "placeName", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        return fetchedResultsController
    }()
    
    // MARK: - Places
    
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
                        let place = Place(placeName: placeProperty["placeName"]!, vicinity: placeProperty["vicinity"]!, context: self.sharedContext)
                        
                        place.pin = self.pin
                        
//                        self.pin.places.append(place)
                    }
                    
                    CoreDataStackManager.sharedInstance().saveContext()
                    self.fetchedResultsController.performFetch(nil)
                    
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
//        return pin.places.count
        if let objectCount = fetchedResultsController.fetchedObjects?.count {
            return objectCount
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PlaceCell", forIndexPath: indexPath) as! UITableViewCell
        
//        let place = pin.places[indexPath.row]
        let place = fetchedResultsController.objectAtIndexPath(indexPath) as! Place
        
        // Configure the cell...
        
        cell.textLabel?.text = place.placeName
        cell.detailTextLabel?.text = place.vicinity
        
        return cell
    }

}
