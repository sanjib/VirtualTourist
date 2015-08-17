//
//  TabBarViewController.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/17/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {

    var pin: Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        println("pin coords: \(pin.coordinate.latitude), \(pin.coordinate.longitude)")
    }

}
