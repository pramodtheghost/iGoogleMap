//
//  MapTasks.swift
//  iGoogleMap
//
//  Created by Pramod Singh Rawat on 26/02/18.
//  Copyright © 2018 iPramodSinghRawat. All rights reserved.
//

import UIKit

class MapTasks: NSObject {

    let baseURLGeocode = "https://maps.googleapis.com/maps/api/geocode/json?"
    
    var lookupAddressResults: NSDictionary!
    
    var fetchedFormattedAddress: String!
    
    var fetchedAddressLongitude: Double!
    
    var fetchedAddressLatitude: Double!
    
    let baseURLDirections = "https://maps.googleapis.com/maps/api/directions/json?"
    
    var selectedRoute: NSDictionary!
    
    var overviewPolyline: Dictionary<NSObject, AnyObject>!
    
    var originCoordinate: CLLocationCoordinate2D!
    
    var destinationCoordinate: CLLocationCoordinate2D!
    
    var originAddress: String!
    
    var destinationAddress: String!
    
    var totalDistanceInMeters: UInt = 0
    
    var totalDistance: String!
    
    var totalDurationInSeconds: UInt = 0
    
    var totalDuration: String!
    
    override init() {
        super.init()
    }
    
    func geocodeAddress(address: String!, withCompletionHandler completionHandler: @escaping ((_ status: String, _ success: Bool) -> Void)) {
        if let lookupAddress = address {
            var geocodeURLString = baseURLGeocode + "address=" + lookupAddress
            //geocodeURLString = geocodeURLString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
            
            geocodeURLString = geocodeURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            
            
            //let encodedHost = unencodedHost.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
            //let encodedHost = unencodedHost.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            let geocodeURL = NSURL(string: geocodeURLString)
            
            DispatchQueue.main.async(execute: { () -> Void in
                let geocodingResultsData = NSData(contentsOf: geocodeURL! as URL)
                
                var error: NSError?
                var dictionary: NSDictionary!
                do{
                    
                    dictionary = try JSONSerialization.jsonObject(with: geocodingResultsData! as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                }
                catch{
                    print("dictionary error: \(error)")
                    dictionary = nil
                }
                
                //, error: &error
                if (error != nil) {
                    print(error)
                    completionHandler("", false)
                }
                else {
                    // Get the response status.
                    let status = dictionary["status" as NSObject] as! String!
                    
                    if status == "OK" {
                        
                        let allResults = dictionary["results" as NSObject] as! Array<NSDictionary>
                        self.lookupAddressResults = allResults[0] as NSDictionary!
                        
                        // Keep the most important values.
                        self.fetchedFormattedAddress = self.lookupAddressResults["formatted_address"] as! String
                        let geometry = self.lookupAddressResults["geometry"] as! NSDictionary
                        
                        self.fetchedAddressLongitude = ((geometry["location"] as! NSDictionary)["lng"] as! NSNumber).doubleValue
                        
                        self.fetchedAddressLatitude = ((geometry["location"] as! NSDictionary)["lat"] as! NSNumber).doubleValue
                        
                        completionHandler(status!, true)
                        
                        
                    }
                    else {
                        completionHandler(status!, false)
                    }
                }
            })
        }
        else {
            completionHandler("No valid address.", false)
        }
    }
    
    func getDirections(origin: String!, destination: String!, waypoints: Array<String>!, travelMode: TravelModes!, completionHandler: @escaping ((_ status: String, _ success: Bool) -> Void)) {
        
        if let originLocation = origin {
            if let destinationLocation = destination {
                var directionsURLString = baseURLDirections + "origin=" + originLocation + "&destination=" + destinationLocation
                
                if let routeWaypoints = waypoints {
                    directionsURLString += "&waypoints=optimize:true"
                    
                    for waypoint in routeWaypoints {
                        directionsURLString += "|" + waypoint
                    }
                }
                
                if let travel = travelMode {
                    var travelModeString = ""
                    
                    switch travelMode.rawValue {
                    case TravelModes.walking.rawValue:
                        travelModeString = "walking"
                        
                    case TravelModes.bicycling.rawValue:
                        travelModeString = "bicycling"
                        
                    default:
                        travelModeString = "driving"
                    }
                    
                    directionsURLString += "&mode=" + travelModeString
                }
                
                
                //directionsURLString = directionsURLString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
                
                directionsURLString = directionsURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                
                let directionsURL = NSURL(string: directionsURLString)
                
                //print(directionsURL)
                
                DispatchQueue.main.async(execute: { () -> Void in
                    let directionsData = NSData(contentsOf: directionsURL! as URL)
                    
                    var error: NSError?
                    /*
                     let dictionary: Dictionary<NSObject, AnyObject> = JSONSerialization.JSONObjectWithData(directionsData!, options: JSONSerialization.ReadingOptions.MutableContainers, error: &error) as Dictionary<NSObject, AnyObject>
                     
                     */
                    
                    var dictionary: Dictionary<NSObject, AnyObject>!
                    do{
                        
                        //dictionary = try JSONSerialization.jsonObject(with: directionsData! as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                        dictionary = try JSONSerialization.jsonObject(with: directionsData as! Data,
                                                                      options:JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary
                        
                    }
                    catch{
                        print("dictionary error: \(error)")
                        dictionary = nil
                    }
                    
                    if (error != nil) {
                        print(error)
                        completionHandler("", false)
                    }
                    else {
                        if((dictionary) != nil){
                            
                            let status = dictionary["status" as NSObject] as! String
                            
                            if status == "OK" {
                                self.selectedRoute = (dictionary["routes" as NSObject] as! Array<Dictionary<NSObject, AnyObject>>)[0] as NSDictionary!
                                
                                self.overviewPolyline = (self.selectedRoute["overview_polyline"] as! NSDictionary) as Dictionary<NSObject, AnyObject>!
                                
                                let legs = self.selectedRoute["legs" as NSObject] as! Array<NSDictionary>
                                
                                let startLocationDictionary = legs[0]["start_location"] as! NSDictionary
                                self.originCoordinate = CLLocationCoordinate2DMake(startLocationDictionary["lat"] as! Double, startLocationDictionary["lng"] as! Double)
                                
                                let endLocationDictionary = legs[legs.count - 1]["end_location"] as! NSDictionary
                                self.destinationCoordinate = CLLocationCoordinate2DMake(endLocationDictionary["lat"] as! Double, endLocationDictionary["lng"] as! Double)
                                
                                self.originAddress = legs[0]["start_address"] as! String
                                self.destinationAddress = legs[legs.count - 1]["end_address"] as! String
                                
                                self.calculateTotalDistanceAndDuration()
                                
                                completionHandler(status, true)
                            }
                            else {
                                completionHandler(status, false)
                            }
                        }else{
                            print ("Dicnery is Nil")
                        }
                        
                        
                    }
                })
            }
            else {
                completionHandler("Destination is nil.", false)
            }
        }
        else {
            completionHandler("Origin is nil", false)
        }
    }
    
    func calculateTotalDistanceAndDuration() {
        let legs = self.selectedRoute["legs"] as! Array<NSDictionary>
        
        totalDistanceInMeters = 0
        totalDurationInSeconds = 0
        
        for leg in legs {
            totalDistanceInMeters += (leg["distance"] as! NSDictionary)["value"] as! UInt
            totalDurationInSeconds += (leg["duration"] as! NSDictionary)["value"] as! UInt
        }
        
        
        let distanceInKilometers: Double = Double(totalDistanceInMeters / 1000)
        totalDistance = "Total Distance: \(distanceInKilometers) Km"
        
        
        let mins = totalDurationInSeconds / 60
        let hours = mins / 60
        let days = hours / 24
        let remainingHours = hours % 24
        let remainingMins = mins % 60
        let remainingSecs = totalDurationInSeconds % 60
        
        totalDuration = "Duration: \(days) d, \(remainingHours) h, \(remainingMins) mins, \(remainingSecs) secs"
    }
}
