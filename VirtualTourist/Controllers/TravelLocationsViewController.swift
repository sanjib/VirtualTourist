//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/17/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var travelLocationsMapView: MKMapView!
    @IBOutlet weak var editModeButton: UIBarButtonItem!
    @IBOutlet weak var toolbar: UIToolbar!

    var selectedPin: Pin? = nil
    var inEditMode = false
    
    let pinIdentifier = "pinIdentifier"
    let pinSegueIdentifier = "PinSegue"
    
    var dragStateEnded = false    
    var currentRegion: CoordinateRegion? = nil
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        travelLocationsMapView.delegate = self
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "OK", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        
        // Trigger saveCurrentRegion when app goes to background or terminates
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveCurrentRegion", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveCurrentRegion", name: UIApplicationWillTerminateNotification, object: nil)
        
        // Set the region user last viewed
        if NSFileManager.defaultManager().fileExistsAtPath(currentRegionFilePath) {
            currentRegion = NSKeyedUnarchiver.unarchiveObjectWithFile(currentRegionFilePath) as? CoordinateRegion
            travelLocationsMapView.setRegion(currentRegion!.currentRegion, animated: false)
        }
        
        addDropPinGestureRecognizer()
        
        // CoreData
        let pins = fetchAllPins()
        if !pins.isEmpty {
            for pin in pins {
                travelLocationsMapView.addAnnotation(pin)
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        displayEditButtonEnabledState()
        displayToolbarHiddenState()
        
        selectedPin = nil
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillTerminateNotification, object: nil)
    }
    
    // MARK: - Edit mode
    
    struct EditModeButtonTitle {
        static let edit = "Edit"
        static let done = "Done"
    }
    
    @IBAction func editModeButtonAction(sender: UIBarButtonItem) {
        inEditMode = inEditMode == true ? false : true
        
        if inEditMode == true {
            editModeButton.title = EditModeButtonTitle.done
            removeDropPinGestureRecognizer()
        } else {
            editModeButton.title = EditModeButtonTitle.edit
            addDropPinGestureRecognizer()
        }
        
        displayEditButtonEnabledState()
        displayToolbarHiddenState()
    }
    
    private func displayEditButtonEnabledState() {
        if fetchAllPins().count > 0 {
            editModeButton.enabled = true
        } else {
            editModeButton.enabled = false
        }
    }
    
    private func displayToolbarHiddenState() {
        if inEditMode == true {
            toolbar.hidden = false
        } else {
            toolbar.hidden = true
        }
    }
    
    // MARK: - Gesture recognizer
    
    var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
    func addDropPinGestureRecognizer() {
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "dropPin:")
        longPressGestureRecognizer.minimumPressDuration = 0.4
        view.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    func removeDropPinGestureRecognizer() {
        view.removeGestureRecognizer(longPressGestureRecognizer)
    }
    
    // MARK: - CoreData
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    func fetchAllPins() -> [Pin] {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: sharedContext)
        
        var error: NSError? = nil
        var results = sharedContext.executeFetchRequest(fetchRequest, error: &error)
        if let error = error {
            println("error fetching pins: \(error.localizedDescription)")
            return [Pin]()
        }
        return results as! [Pin]
    }
    
    // MARK: - Pins
    
    func dropPin(gestureRecognizer: UIGestureRecognizer) {
        // only allow pin to be dropped on state .Began, otherwise we will end up with a series of pins
        if gestureRecognizer.state != UIGestureRecognizerState.Began {
            return
        }
        
        let touchPoint = gestureRecognizer.locationInView(travelLocationsMapView)
        let touchCoordinate = travelLocationsMapView.convertPoint(touchPoint, toCoordinateFromView: travelLocationsMapView)
        
        let pin = Pin(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude, context: sharedContext)
        CoreDataStackManager.sharedInstance().saveContext()
        
        travelLocationsMapView.addAnnotation(pin)
        displayEditButtonEnabledState()
        getFlickrPhotoProperties(pin)
    }
    
    func deletePin(pin: Pin) {
        travelLocationsMapView.removeAnnotation(pin)
        sharedContext.deleteObject(pin)
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func updatePin(pin: Pin) {
        if !pin.photos.isEmpty {
            for photo in pin.photos {
                photo.pin = nil
            }
        }
        if !pin.places.isEmpty {
            for place in pin.places {
                place.pin = nil
            }
        }
        CoreDataStackManager.sharedInstance().saveContext()
        getFlickrPhotoProperties(pin)
    }
    
    // MARK: - Photos
    
    // Pre-fetch photo data from Flickr as soon as a pin is dropped
    func getFlickrPhotoProperties(pin: Pin) {
        if pin.photoPropertiesFetchInProgress == true {
            return
        } else {
            pin.photoPropertiesFetchInProgress = true
        }
        
        FlickrClient.sharedInstance().photosSearch(pin) { photoProperties, errorString in
            if errorString != nil {

            } else {
                if let photoProperties = photoProperties {
                    for photoProperty in photoProperties {
                        println(photoProperty)
                        let photo = Photo(imageName: photoProperty["imageName"]!, remotePath: photoProperty["remotePath"]!, context: self.sharedContext)
                        photo.pin = pin
                    }
                    dispatch_async(dispatch_get_main_queue()) {
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                }
            }
            pin.photoPropertiesFetchInProgress = false
        }
    }
    
    // MARK: - Map delegates
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(pinIdentifier) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: pinIdentifier)
        } else {
            pinView!.annotation = annotation
        }
        
        pinView!.animatesDrop = true
        pinView!.draggable = true
        
        // immediately select the pinView (needs to be selected first to be dragged)
        pinView!.setSelected(true, animated: false)
        
        return pinView
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        // deselect pin and setSelected state to true
        // this allows any pin on the map to be moved to a new location with a
        // single long press gesture or with a single tap segue to photo album
        mapView.deselectAnnotation(view.annotation, animated: false)
        view.setSelected(true, animated: false)
        
        let pin = view.annotation as! Pin
        
        // Update Pin
        if dragStateEnded == true {
            updatePin(pin)
            dragStateEnded = false
            return
        }
        
        // Delete Pin, else segue
        if inEditMode == true {
            deletePin(pin)
        } else {
            selectedPin = pin
            performSegueWithIdentifier(pinSegueIdentifier, sender: self)
        }
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        // track the immediate result of an .Ending pin drag state
        if newState == MKAnnotationViewDragState.Ending {
            dragStateEnded = true
        }
    }
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        currentRegion = CoordinateRegion(region: mapView.region)
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == pinSegueIdentifier {
            let vc = segue.destinationViewController as! TabBarViewController
            vc.pin = selectedPin
        }
    }

    // MARK: - Helpers
    
    var currentRegionFilePath: String {
        let url = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent("currentRegion").path!
    }
    
    func saveCurrentRegion() {
        if let currentRegion = currentRegion {
            NSKeyedArchiver.archiveRootObject(currentRegion, toFile: currentRegionFilePath)
        }
    }
    
}
