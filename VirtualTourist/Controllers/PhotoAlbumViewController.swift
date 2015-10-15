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
    let cellsPerRowInPortraitMode: CGFloat = 3
    let cellsPerRowInLandscpaeMode: CGFloat = 6
    let minimumSpacingPerCell: CGFloat = 5
    
    private let photoPlaceholderImageData = NSData(data: UIImagePNGRepresentation(UIImage(named: "photoPlaceholder")!)!)
    
    private struct ToolbarButtonTitle {
        static let create = "New Collection"
        static let delete = "Delete Selected Photos"
    }
    
    private var selectedIndexes = [NSIndexPath]()
    private var insertedIndexPaths: [NSIndexPath]!
    private var deletedIndexPaths: [NSIndexPath]!
    private var updatedIndexPaths: [NSIndexPath]!
    private var numberOfPhotoCurrentlyDownloading = 0
    
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
        do {
            try fetchedResultsController.performFetch()
        } catch {
            NSLog("Fetch failed: \(error)")
        }
        
        if pin.photos.isEmpty {
            getFlickrPhotos()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.title = "Photos"
     
        let region = MKCoordinateRegionMakeWithDistance(pin.coordinate, 100_000, 100_000)
        mapView.setRegion(region, animated: false)
        mapView.addAnnotation(pin)
        
        displayToolbarEnabledState()
    }
    
    // MARK: - CoreData
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext!
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
        
        if pin.photoPropertiesFetchInProgress == true {
            return
        } else {
            pin.photoPropertiesFetchInProgress = true
        }
        
        noImagesFoundLabel.hidden = true
        toolbarButton.enabled = false
        
        FlickrClient.sharedInstance.photosSearch(pin) { photoProperties, errorString in
            if errorString != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator.stopAnimating()
                    self.toolbarButton.enabled = true
                    self.noImagesFoundLabel.hidden = false
                }
            } else {
                if let photoProperties = photoProperties {
                    for photoProperty in photoProperties {
                        let photo = Photo(imageName: photoProperty["imageName"]!, remotePath: photoProperty["remotePath"]!, context: self.sharedContext)
                        photo.pin = self.pin
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        CoreDataStackManager.sharedInstance.saveContext()
                    }
                }
            }
            self.pin.photoPropertiesFetchInProgress = false
        }
    }
    
    private func createNewPhotoCollection() {
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            for object in fetchedObjects {
                let photo = object as! Photo
                sharedContext.deleteObject(photo)
            }
            CoreDataStackManager.sharedInstance.saveContext()
        }
        getFlickrPhotos()
    }
    
    private func deleteSelectedPhotos() {
        var photosToDelete = [Photo]()
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        for photo in photosToDelete {
            sharedContext.deleteObject(photo)
        }
        CoreDataStackManager.sharedInstance.saveContext()
        
        selectedIndexes = [NSIndexPath]()
        setToolbarButtonTitle()
        displayToolbarEnabledState()
    }
    
    // MARK: - Toolbar
    
    @IBAction func toolbarButtonAction(sender: UIBarButtonItem) {
        if selectedIndexes.count > 0 {
            deleteSelectedPhotos()
        } else {
            createNewPhotoCollection()
        }
    }
    
    private func setToolbarButtonTitle() {
        if selectedIndexes.count > 0 {
            toolbarButton.title = ToolbarButtonTitle.delete
        } else {
            toolbarButton.title = ToolbarButtonTitle.create
        }
    }
    
    private func displayToolbarEnabledState() {
        if toolbarButton.title == ToolbarButtonTitle.create {
            if pin.photoPropertiesFetchInProgress == true || numberOfPhotoCurrentlyDownloading > 0 {
                toolbarButton.enabled = false
            } else {
                toolbarButton.enabled = true
            }
        } else {
            toolbarButton.enabled = true
        }
    }
    
    // MARK: - CollectionView layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = minimumSpacingPerCell
        layout.minimumInteritemSpacing = minimumSpacingPerCell
        
        var width: CGFloat!
        if UIApplication.sharedApplication().statusBarOrientation.isLandscape == true {
            width = (CGFloat(collectionView.frame.size.width) / cellsPerRowInLandscpaeMode) - (minimumSpacingPerCell - (minimumSpacingPerCell / cellsPerRowInLandscpaeMode))
        } else {
            width = (CGFloat(collectionView.frame.size.width) / cellsPerRowInPortraitMode) - (minimumSpacingPerCell - (minimumSpacingPerCell / cellsPerRowInPortraitMode))
        }
        
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        collectionView.performBatchUpdates(nil, completion: nil)
    }
    
    // MARK: - CollectionView delegates
    
    func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        if photo.didFetchImageData == false {
            return false
        }
        return true
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        if photo.didFetchImageData == false {
            return false
        }
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedIndexes.append(indexPath)
        setToolbarButtonTitle()
        displayToolbarEnabledState()
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        }
        setToolbarButtonTitle()
        displayToolbarEnabledState()
    }
    
    // MARK: - CollectionView data source
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellReuseIdentifier, forIndexPath: indexPath) as! PhotoAlbumCollectionViewCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    // MARK: - Configure cell
    
    func configureCell(cell: PhotoAlbumCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if let imageData = photo.imageData {
            cell.activityIndicator.stopAnimating()
            cell.backgroundView = UIImageView(image: UIImage(data: imageData))
        } else {
            cell.backgroundView = UIImageView(image: UIImage(data: photoPlaceholderImageData))
            cell.activityIndicator.startAnimating()
            
            if photo.fetchInProgress == false {
                numberOfPhotoCurrentlyDownloading += 1
                photo.fetchImageData { fetchComplete in
                    self.numberOfPhotoCurrentlyDownloading -= 1
                    if fetchComplete == true {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.displayToolbarEnabledState()
                        }
                    }
                }
            }
        }
        
        displayToolbarEnabledState()
        
        // Selected state properties
        let backgroundView = UIView(frame: cell.contentView.frame)
        backgroundView.backgroundColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.7)
        
        let checkmarkImageViewFrame = CGRect(x: cell.contentView.frame.origin.x, y: cell.contentView.frame.origin.y, width: cell.frame.width, height: cell.frame.height)
        let checkmarkImageView = UIImageView(frame: checkmarkImageViewFrame)
        checkmarkImageView.contentMode = UIViewContentMode.BottomRight
        checkmarkImageView.image = UIImage(named: "checkmark")
        backgroundView.addSubview(checkmarkImageView)
        cell.selectedBackgroundView = backgroundView
    }
    
    // MARK: - NSFetchedResultsController delegates
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        self.activityIndicator.stopAnimating()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
        case .Delete:
            deletedIndexPaths.append(indexPath!)
        case .Update:
            updatedIndexPaths.append(indexPath!)
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {        
        collectionView.performBatchUpdates({
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
        }, completion: nil)
    }
}
