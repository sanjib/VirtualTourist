//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/17/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import Foundation

//let bboxEdge = 0.005
//let bboxEdge = 0.01
//let bboxEdge = 0.05
let bboxEdge = 0.1

class FlickrClient: CommonRESTApi {
    class func sharedInstance() -> FlickrClient {
        struct Shared {
            static let instance = FlickrClient()
        }
        return Shared.instance
    }
    
    override init() {
        super.init()
        super.additionalMethodParams = [
            "api_key": Constants.restApiKey,
            "format": "json",
            "nojsoncallback": 1,
            "safe_search": 1,
        ]
    }
    
    private struct Constants {
        static let baseURL = "https://api.flickr.com/services/rest/"
        static let photoSourceURL = "https://farm{farmId}.staticflickr.com/{serverId}/{photoId}_{secret}_{imageSize}.jpg"
        static let restApiKey = "67fda1c0b25a2d0f325990f46d42fbb2"
        static let photosPerPage = 21
        static let maxNumberOfResultsReturnedByFlickr = 4000
    }
    
    private struct Methods {
        static let photosSearch = "flickr.photos.search"
    }
    
    private struct ImageSize {
        static let smallSquare = "s"
        static let largeSquare = "q"
        static let thumbnail   = "t"
        static let small240    = "m"
        static let small320    = "n"
        static let medium500   = "-"
        static let medium640   = "z"
        static let medium800   = "c"
        static let large1024   = "b"
        static let large1600   = "h"
        static let large2048   = "k"
        static let original    = "o"
    }
    
    func photosSearch(pin: Pin, completionHandler: (photoProperties: [[String:String]]?, errorString: String?) -> Void) {
        let bboxParms = photoSearchGetBboxParams(pin.latitude, longitude: pin.longitude)
        photoSearchGetRandomPage(bboxParms) { randomPageNumber, errorString in
            if errorString != nil {
                completionHandler(photoProperties: nil, errorString: errorString)
            } else {
                let methodParams: [String:AnyObject] = [
                    "method": Methods.photosSearch,
                    "bbox": bboxParms,
                    "per_page": Constants.photosPerPage,
                    "page": randomPageNumber!
                ]
                let url = Constants.baseURL + self.urlParamsFromDictionary(methodParams)
                self.httpGet(url) { result, error in
                    if error != nil {
                        completionHandler(photoProperties: nil, errorString: error?.localizedDescription)
                    } else {
                        if let jsonPhotosDictionary = result["photos"] as? NSDictionary {
                            if let jsonPhotoDataArray = jsonPhotosDictionary["photo"] as? NSArray {
                                var photoProperties = [[String:String]]()
                                for jsonPhotoData in jsonPhotoDataArray {
                                    if let photoProperty = self.photoParamsToProperties(jsonPhotoData as! NSDictionary) {
                                        photoProperties.append(photoProperty)
                                    }
                                }
                                completionHandler(photoProperties: photoProperties, errorString: nil)
                            } else {
                                completionHandler(photoProperties: nil, errorString: "Couldn't get photo set from Flickr. Please try again later or try a different location.")
                            }
                        } else {
                            completionHandler(photoProperties: nil, errorString: "Couldn't get photo set from Flickr. Please try again later or try a different location.")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func photoParamsToProperties(jsonData: NSDictionary) -> [String:String]? {
        let photoId = jsonData["id"] as? String
        let secret = jsonData["secret"] as? String
        let serverId = jsonData["server"] as? String
        let farmId = jsonData["farm"] as? Int
        if photoId != nil && secret != nil && serverId != nil && farmId != nil {
            let imageSize = ImageSize.largeSquare
            let photoParams: [String:String] = [
                "photoId": photoId!,
                "secret": secret!,
                "serverId": serverId!,
                "farmId": "\(farmId!)",
                "imageSize": imageSize
            ]
            let imageName = "\(photoId!)_\(secret!)_\(imageSize).jpg"
            let remotePath = self.urlKeySubstitute(Constants.photoSourceURL, kvp: photoParams)
            return [
                "imageName": imageName,
                "remotePath": remotePath
            ]
        }
        return nil
    }
    
    private func photoSearchGetBboxParams(latitude: Double, longitude: Double) -> String {
        let latMin = -90.0
        let latMax = 90.0
        let longMin = -180.0
        let longMax = 180.0
        
        var bBoxLatMin = latitude - bboxEdge
        var bBoxLongMin = longitude - bboxEdge
        var bBoxLatMax = latitude + bboxEdge
        var bBoxLongMax = longitude + bboxEdge
        
        if bBoxLatMax > latMax {
            bBoxLatMax = latMax
            bBoxLatMin = latMax - bboxEdge
        } else if bBoxLatMin < latMin {
            bBoxLatMin = latMin
            bBoxLatMax = latMax - bboxEdge
        }
        
        if bBoxLongMax > longMax {
            bBoxLongMax = (bBoxLongMax - longMax) + longMin
        } else if bBoxLongMin < longMin {
            bBoxLongMin = longMax - (bBoxLongMin + longMin)
        }
        
        return "\(bBoxLongMin),\(bBoxLatMin),\(bBoxLongMax),\(bBoxLatMax)"
    }
    
    private func photoSearchGetRandomPage(bboxParams: String, completionHandler: (randomPageNumber: Int?, errorString: String?) -> Void) {
        let methodParams: [String:AnyObject] = [
            "method": Methods.photosSearch,
            "bbox": bboxParams,
            "per_page": 1   // get 1 result per page as we only want the "total" figure to generate a random page number
        ]
        let url = Constants.baseURL + urlParamsFromDictionary(methodParams)
        httpGet(url) { result, error in
            if error != nil {
                completionHandler(randomPageNumber: nil, errorString: error?.localizedDescription)
            } else {
                if let photos = result["photos"] as? NSDictionary {
                    if let total = (photos["total"] as? String)?.toInt() {
                        if total > 0 {
                            if let randomPageNumber = self.photoSearchGetRandomPageNumber(total) {
                                completionHandler(randomPageNumber: randomPageNumber, errorString: nil)
                            } else {
                                completionHandler(randomPageNumber: nil, errorString: "Couldn't get a random page number. Please try again later or try a different location.")
                            }
                        } else {
                            completionHandler(randomPageNumber: nil, errorString: "Couldn't get photos from Flickr. Please try again later or try a different location.")
                        }
                    } else {
                        completionHandler(randomPageNumber: nil, errorString: "Couldn't get photos from Flickr. Please try again later or try a different location.")
                    }
                } else {
                    completionHandler(randomPageNumber: nil, errorString: "Couldn't get photos from Flickr. Please try again later or try a different location.")
                }
            }
        }
    }
    
    private func photoSearchGetRandomPageNumber(totalResults: Int) -> Int? {
        let totalResults = min(totalResults, Constants.maxNumberOfResultsReturnedByFlickr)
        if totalResults <= 0 {
            return nil
        }
        
        let numberOfPages: Int
        if totalResults <= Constants.photosPerPage {
            numberOfPages = 1
        } else {
            numberOfPages = totalResults / Constants.photosPerPage
        }
        
        println("total results: \(totalResults)")
        println("results per page: \(numberOfPages)")
        
        let randomPageNumber: Int?
        if numberOfPages > 1 {
            randomPageNumber = Int(arc4random_uniform(UInt32(numberOfPages))) + 1 // add 1 since page numbers start at 1
        } else {
            randomPageNumber = 1
        }
        
        println("random page number: \(randomPageNumber)")
        return randomPageNumber
    }
}
