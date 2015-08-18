//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/17/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var travelLocationsMapView: MKMapView!
    @IBOutlet weak var editModeButton: UIBarButtonItem!
    @IBOutlet weak var toolbar: UIToolbar!
    
    var pins = [Pin]()
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        displayEditButtonEnabledState()
        displayToolbarHiddenState()
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
        if pins.count > 0 {
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
    
    // MARK: - Pins
    
    func dropPin(gestureRecognizer: UIGestureRecognizer) {
        // only allow pin to be dropped on state .Began, otherwise we will end up with a series of pins
        if gestureRecognizer.state != UIGestureRecognizerState.Began {
            return
        }
        
        let touchPoint = gestureRecognizer.locationInView(travelLocationsMapView)
        let touchCoordinate = travelLocationsMapView.convertPoint(touchPoint, toCoordinateFromView: travelLocationsMapView)
        
        let pin = Pin(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude)
        travelLocationsMapView.addAnnotation(pin)
        
        pins.append(pin)
        displayEditButtonEnabledState()
    }
    
    func deletePin(pin: Pin) {
        travelLocationsMapView.removeAnnotation(pin)
        if let indexOfPinToDelete = find(pins, pin) {
            pins.removeAtIndex(indexOfPinToDelete)
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
        
        // immediately select the pinView (needs to be selected first, then dragged)
        // so that user can drag it to a new location if desired
        pinView!.setSelected(true, animated: false)
        
        return pinView
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        // deselect the pin immediately after selection so that:
        // - user can select it for an actual segue (pin gets selected after being dragged to a new location)
        // - user can select the pin again after viewing an album (pin remains selected after user selection)
        mapView.deselectAnnotation(view.annotation, animated: false)
        
        // as a pin will automatically get selected after being dragged to a new location
        // we want avoid an automatic segue so we track this with variable dragStateEnded
        if dragStateEnded == true {
            dragStateEnded = false
            return
        }
        
        if inEditMode == true {
            deletePin(view.annotation as! Pin)
        } else {
            selectedPin = view.annotation as? Pin
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
