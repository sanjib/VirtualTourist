//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/17/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var pin: Pin!
    
    let cellReuseIdentifier = "PhotoCell"
    
    // Cell layout properties
    let minimumSpacingBetweenCells = 5
    let cellsPerRowInPortraitMode = 3
    
    private let photoPlaceholderImageData = NSData(data: UIImagePNGRepresentation(UIImage(named: "photoPlaceholder")))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.userInteractionEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true
        activityIndicator.hidesWhenStopped = true
        activityIndicator.stopAnimating()
        
        let tc = tabBarController as! TabBarViewController
        pin = tc.pin

        if pin.photos.count == 0 {
            getFlickrPhotos()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.title = "Photos"
     
        let region = MKCoordinateRegionMakeWithDistance(pin.coordinate, 100_000, 100_000)
        mapView.setRegion(region, animated: false)
        mapView.addAnnotation(pin)
    }
    
    func getFlickrPhotos() {
        activityIndicator.startAnimating()
        FlickrClient.sharedInstance().photosSearch(pin) { photoProperties, errorString in
            if errorString != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator.stopAnimating()
                }
            } else {
                if let photoProperties = photoProperties {
                    for photoProperty in photoProperties {
                        println(photoProperty)
                        let photo = Photo(imageName: photoProperty["imageName"]!, remotePath: photoProperty["remotePath"]!)
                        self.pin.photos.append(photo)
                    }
                    dispatch_async(dispatch_get_main_queue()) {
                        self.activityIndicator.stopAnimating()
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    // MARK: - CollectionView layout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        // Use width in portrait mode; height in landscape
        let deviceOrientation = UIDevice.currentDevice().orientation
        var widthForCollection: CGFloat!
        if (deviceOrientation == UIDeviceOrientation.Portrait) || (deviceOrientation == UIDeviceOrientation.PortraitUpsideDown) {
            widthForCollection = view.frame.width
        } else {
            widthForCollection = view.frame.height
        }
        
        // To determine width of a cell we divide frame width by cells per row
        // Then compensate it by subtracting minimum spacing between cells
        // The last cell doesn't need compensation for spacing
        let width = Float(widthForCollection / CGFloat(cellsPerRowInPortraitMode)) -
            Float(minimumSpacingBetweenCells - (minimumSpacingBetweenCells / cellsPerRowInPortraitMode))
        let height = width
        return CGSize(width: CGFloat(width), height: CGFloat(height))
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return CGFloat(minimumSpacingBetweenCells)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return CGFloat(minimumSpacingBetweenCells)
    }
    
    // MARK: - CollectionView delegates
    
    func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
    }
    
    // MARK: - CollectionView data source
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pin.photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellReuseIdentifier, forIndexPath: indexPath) as! PhotoAlbumCollectionViewCell
        
        let photo = pin.photos[indexPath.row]
        
        // Configure the cell
        
        if let imageData = photo.imageData {
            println("image exists: \(photo.imageName)")
            cell.activityIndicator.stopAnimating()
            cell.backgroundView = UIImageView(image: UIImage(data: imageData))
        } else {
            cell.backgroundView = UIImageView(image: UIImage(data: photoPlaceholderImageData))
            print("need to get image ...")
            cell.activityIndicator.startAnimating()
            photo.fetchImageData { data, error in
                if error != nil {
                    println("error fetchImageData: \(error)")
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.collectionView.reloadItemsAtIndexPaths([indexPath])
                    }
                    println("got image: \(photo.imageName)")
                }
            }
        }
        
        // Selected state properties
        let backgroundView = UIView(frame: cell.contentView.frame)
        backgroundView.backgroundColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.7)
        
        let checkmarkImageView = UIImageView(frame: cell.contentView.frame)
        checkmarkImageView.contentMode = UIViewContentMode.BottomRight
        checkmarkImageView.image = UIImage(named: "checkmark")
        backgroundView.addSubview(checkmarkImageView)
        cell.selectedBackgroundView = backgroundView
        
        return cell
    }

}
