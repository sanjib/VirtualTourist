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
        tableView.allowsSelection = false
        activityIndicator.hidesWhenStopped = true
        noPlacesFoundLabel.hidden = true
        activityIndicator.stopAnimating()

        let tc = tabBarController as! TabBarViewController
        pin = tc.pin
        
        // CoreData
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(nil)
        
        if pin.places.isEmpty {
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
        return CoreDataStackManager.sharedInstance.managedObjectContext!
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
        
        GooglePlacesClient.sharedInstance.placesSearch(pin) { placesProperties, errorString in
            if errorString != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator.stopAnimating()
                    self.noPlacesFoundLabel.hidden = false
                }
            } else {
                if let placesProperties = placesProperties {
                    for placeProperty in placesProperties {
                        let place = Place(placeName: placeProperty["placeName"]!, vicinity: placeProperty["vicinity"]!, context: self.sharedContext)
                        place.pin = self.pin
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        CoreDataStackManager.sharedInstance.saveContext()
                        self.activityIndicator.stopAnimating()
                    }
                }
            }
        }
    }
    
    // MARK: - TableView delegates & data source
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        switch (editingStyle) {
        case .Delete:
            let place = fetchedResultsController.objectAtIndexPath(indexPath) as! Place
            sharedContext.deleteObject(place)
            CoreDataStackManager.sharedInstance.saveContext()
        default:
            return
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PlaceCell", forIndexPath: indexPath) as! UITableViewCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
    // MARK: - Configure cell
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let place = fetchedResultsController.objectAtIndexPath(indexPath) as! Place
        cell.textLabel?.text = place.placeName
        cell.detailTextLabel?.text = place.vicinity
    }
}
