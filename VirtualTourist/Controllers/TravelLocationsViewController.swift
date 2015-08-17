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
    
    var selectedPin: Pin? = nil

    var longPressGestureRecognizer: UILongPressGestureRecognizer!
    let pinIdentifier = "pinIdentifier"
    let pinSegueIdentifier = "PinSegue"
    
    var dragStateEnded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        travelLocationsMapView.delegate = self
        
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "dropPin:")
        view.addGestureRecognizer(longPressGestureRecognizer)
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
        
        selectedPin = view.annotation as? Pin
        performSegueWithIdentifier(pinSegueIdentifier, sender: self)
    }
    
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        // track the immediate result of an .Ending pin drag state
        if newState == MKAnnotationViewDragState.Ending {
            dragStateEnded = true
        }
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == pinSegueIdentifier {
            let vc = segue.destinationViewController as! TabBarViewController
            vc.pin = selectedPin
        }
    }

}
