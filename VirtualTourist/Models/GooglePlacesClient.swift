//
//  GooglePlacesClient.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/17/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

import Foundation

class GooglePlacesClient: CommonRESTApi {
    
    class func sharedInstance() -> GooglePlacesClient {
        struct Shared {
            static let instance = GooglePlacesClient()
        }
        return Shared.instance
    }
    
    override init() {
        super.init()
        super.additionalMethodParams = [
            "key": Constants.restApiKey
        ]
    }
    
    private struct Constants {
        static let baseURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        static let restApiKey = "AIzaSyD8dG0xSBBakjEZtZyFm_MeJkA536dyVuM"
        static let radius = 10_000 // max 50_000
    }
    
    func placesSearch(pin: Pin, completionHandler: (placeProperties: [[String:String]]?, errorString: String?) -> Void) {
        let methodParams: [String:AnyObject] = [
            "location": "\(pin.latitude),\(pin.longitude)",
            "radius": Constants.radius
        ]
        let url = Constants.baseURL + self.urlParamsFromDictionary(methodParams)
        self.httpGet(url) { result, error in
            if error != nil {
                completionHandler(placeProperties: nil, errorString: error?.localizedDescription)
            } else {
                if let jsonPlaccesDataArray = result["results"] as? NSArray {
                    var placeProperties = [[String:String]]()
                    for jsonPlaceData in jsonPlaccesDataArray {
                        if let placeProperty = self.placeParamsToProperties(jsonPlaceData as! NSDictionary) {
                            placeProperties.append(placeProperty)
                        }
                    }
                    completionHandler(placeProperties: placeProperties, errorString: nil)
                } else {
                    completionHandler(placeProperties: nil, errorString: "Couldn't get places information from Google. Please try again later or try a different location.")
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func placeParamsToProperties(jsonData: NSDictionary) -> [String:String]? {
        let placeName = jsonData["name"] as? String
        let vicinity = jsonData["vicinity"] as? String
        if placeName != nil && vicinity != nil {
            // Google Places may return the first object as the place itself where
            // placeName == vicinity; this is not interesting, so we skip it
            if placeName != vicinity {
                return [
                    "placeName": placeName!,
                    "vicinity": vicinity!
                ]
            }
        }
        return nil
    }
}