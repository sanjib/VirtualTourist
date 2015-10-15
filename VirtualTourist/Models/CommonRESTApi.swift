//
//  CommonRESTApi.swift
//  VirtualTourist
//
//  Created by Sanjib Ahmad on 8/17/15.
//  Copyright (c) 2015 Object Coder. All rights reserved.
//

/*
 * The CommonRESTApi provides generalized networking code for web services.
 * It is meant to be sub-classed by vendor-specific custom client classes.
 *
 */

import Foundation

class CommonRESTApi {
    private let session = NSURLSession.sharedSession()
    
    // Can override via subclass
    var additionalHTTPHeaderFields: [String:String]? = nil
    var additionalMethodParams: [String:AnyObject]? = nil
    
    private struct ErrorMessage {
        static let domain = "VirtualTourist"
        static let noInternet = "You appear to be offline, please connect to the Internet to use Virtual Tourist."
        static let invalidURL = "Invalid URL"
        static let emptyURL = "Empty URL"
        static let jsonParseFailed = "Could not parse JSON"
    }
    
    func httpGet(urlString: String, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        if Reachability.isConnectedToNetwork() == false {
            completionHandler(result: nil, error: NSError(domain: ErrorMessage.domain, code: 1, userInfo: [NSLocalizedDescriptionKey : ErrorMessage.noInternet]))
            return
        }
        
        if urlString != "" {
            if let url = NSURL(string: urlString) {
                let request = NSMutableURLRequest(URL: url)
                if let additionalHTTPHeaderFields = additionalHTTPHeaderFields {
                    for (httpHeaderField, value) in additionalHTTPHeaderFields {
                        request.addValue(value, forHTTPHeaderField: httpHeaderField)
                    }
                }
                let task = session.dataTaskWithRequest(request) { data, response, error in
                    if error != nil {
                        completionHandler(result: nil, error: error)
                        return
                    }
                    self.parseJSONData(data!, completionHandler: completionHandler)
                }
                task.resume()
            } else {
                completionHandler(result: nil, error: NSError(domain: ErrorMessage.domain, code: 1, userInfo: [NSLocalizedDescriptionKey : ErrorMessage.invalidURL]))
            }
        } else {
            completionHandler(result: nil, error: NSError(domain: ErrorMessage.domain, code: 1, userInfo: [NSLocalizedDescriptionKey : ErrorMessage.emptyURL]))
        }
    }
    
    // MARK: - Helpers for subclass
    
    func urlKeySubstitute(method: String, kvp: [String:String]) -> String {
        var method = method
        for (key, value) in kvp {
            if method.rangeOfString("{\(key)}") != nil {
                method = method.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
            }
        }
        return method
    }
    
    func urlParamsFromDictionary(parameters: [String : AnyObject]) -> String {
        var urlVars = [String]()
        var parameters = parameters
        if let additionalMethodParams = additionalMethodParams {
            for (key, value) in additionalMethodParams {
                parameters[key] = value
            }
        }
        for (key, value) in parameters {
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    // MARK: - Helpers for JSON parsing
    
    private func parseJSONData(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        do {
            let parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
            completionHandler(result: parsedResult, error: nil)
        } catch {
            completionHandler(result: nil, error: NSError(domain: ErrorMessage.domain, code: 1, userInfo: [NSLocalizedDescriptionKey : ErrorMessage.jsonParseFailed]))
        }
    }
}