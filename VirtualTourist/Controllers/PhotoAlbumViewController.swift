//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/17/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var toolbarButton: UIBarButtonItem!
    @IBOutlet weak var noImagesFoundLabel: UILabel!
    
    var pin: Pin!
    let cellReuseIdentifier = "PhotoCell"
    
    // Cell layout properties
    let minimumSpacingBetweenCells = 5
    let cellsPerRowInPortraitMode = 3
    
    private let photoPlaceholderImageData = NSData(data: UIImagePNGRepresentation(UIImage(named: "photoPlaceholder")))
    
    private struct ToolbarButtonTitle {
        static let create = "New Collection"
        static let delete = "Delete Selected Photos"
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.userInteractionEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true
        activityIndicator.hidesWhenStopped = true
        activityIndicator.stopAnimating()
        noImagesFoundLabel.hidden = true
        setToolbarButtonTitle()
        
        let tc = tabBarController as! TabBarViewController
        pin = tc.pin

        // CoreData
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(nil)
        
        if fetchedResultsController.fetchedObjects?.count == 0 {
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
    
    // MARK: - CoreData
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "imageName", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        return fetchedResultsController
    }()
    
    // MARK: - Photos
    
    private func getFlickrPhotos() {
        activityIndicator.startAnimating()
        toolbarButton.enabled = false
        noImagesFoundLabel.hidden = true
        
        FlickrClient.sharedInstance().photosSearch(pin) { photoProperties, errorString in
            if errorString != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator.stopAnimating()
                    self.toolbarButton.enabled = true
                    self.noImagesFoundLabel.hidden = false
                }
            } else {
                if let photoProperties = photoProperties {
                    for photoProperty in photoProperties {
                        println(photoProperty)
                        let photo = Photo(imageName: photoProperty["imageName"]!, remotePath: photoProperty["remotePath"]!, context: self.sharedContext)
                        photo.pin = self.pin
                    }
                    
                    CoreDataStackManager.sharedInstance().saveContext()
                    self.fetchedResultsController.performFetch(nil)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.activityIndicator.stopAnimating()
                        self.toolbarButton.enabled = true
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    private func createNewPhotoCollection() {
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            for object in fetchedObjects {
                let photo = object as! Photo
                sharedContext.deleteObject(photo)
            }
        }
        CoreDataStackManager.sharedInstance().saveContext()
        fetchedResultsController.performFetch(nil)
        
        collectionView.reloadData()
        getFlickrPhotos()
    }
    
    private func deleteSelectedPhotos() {
        collectionView?.performBatchUpdates({
            if let itemPaths = self.collectionView?.indexPathsForSelectedItems() {
                for indexPath in itemPaths {
                    let photo = self.fetchedResultsController.objectAtIndexPath(indexPath as! NSIndexPath) as! Photo
                    self.sharedContext.deleteObject(photo)
                }
                self.collectionView?.deleteItemsAtIndexPaths(itemPaths)
                CoreDataStackManager.sharedInstance().saveContext()
                self.fetchedResultsController.performFetch(nil)
            }
            }, completion: nil)
        setToolbarButtonTitle()
    }
    
    private func userDidSelectPhotos() -> Bool {
        if let itemPaths = self.collectionView?.indexPathsForSelectedItems() {
            if itemPaths.count > 0 {
                return true
            }
        }
        return false
    }
    
    // MARK: - Toolbar
    
    @IBAction func toolbarButtonAction(sender: UIBarButtonItem) {
        if userDidSelectPhotos() == true {
            deleteSelectedPhotos()
        } else {
            createNewPhotoCollection()
        }
    }
    
    private func setToolbarButtonTitle() {
        if userDidSelectPhotos() == true {
            toolbarButton.title = ToolbarButtonTitle.delete
        } else {
            toolbarButton.title = ToolbarButtonTitle.create
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
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        if photo.imageFetchInProgress == true {
            return false
        }
        return true
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        if photo.imageFetchInProgress == true {
            return false
        }
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        setToolbarButtonTitle()
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        setToolbarButtonTitle()
    }
    
    // MARK: - CollectionView data source
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let objectCount = fetchedResultsController.fetchedObjects?.count {
            return objectCount
        } else {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellReuseIdentifier, forIndexPath: indexPath) as! PhotoAlbumCollectionViewCell

        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
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
                    println("got image: \(photo.imageName)")
                    dispatch_async(dispatch_get_main_queue()) {
                        self.collectionView.reloadItemsAtIndexPaths([indexPath])
                    }
                }
            }
        }
        
        // Selected state properties
        let backgroundView = UIView(frame: cell.contentView.frame)
        backgroundView.backgroundColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.7)
        
        let checkmarkImageViewFrame = CGRect(x: cell.contentView.frame.origin.x, y: cell.contentView.frame.origin.y, width: cell.frame.width, height: cell.frame.height)
        let checkmarkImageView = UIImageView(frame: checkmarkImageViewFrame)
        checkmarkImageView.contentMode = UIViewContentMode.BottomRight
        checkmarkImageView.image = UIImage(named: "checkmark")
        backgroundView.addSubview(checkmarkImageView)
        cell.selectedBackgroundView = backgroundView
        
        return cell
    }

}
