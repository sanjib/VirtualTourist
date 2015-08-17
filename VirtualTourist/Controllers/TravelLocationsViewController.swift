//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/17/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsViewController: UIViewController {
    @IBOutlet weak var travelLocationsMapView: MKMapView!

    var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }

}
