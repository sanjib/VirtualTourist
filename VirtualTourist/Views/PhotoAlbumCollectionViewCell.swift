//
//  PhotoAlbumCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/18/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import UIKit

class PhotoAlbumCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = UIColor.blackColor()
    }
}
