//
//  ServerCommands.swift
//  LapTracker
//
//  Created by Jack Boyce on 1/30/17.
//  Copyright © 2017 Jack Boyce. All rights reserved.
//

import Foundation
import Alamofire
import CoreLocation

class ServerCommands {
    
    public static let homeURL: String = "http://localhost:8000"
    
    public static func login(email: String, password: String, completionHandler: @escaping (String?) -> ()) -> () {
        let payload = ["email": "\(email)", "password": "\(password)"] as [String : Any]
        
        let loginurl = "\(ServerCommands.homeURL)/login"
        Alamofire.request(loginurl, method: .post, parameters: payload).responseString {
            (response) in
            
            let resp = response.result.value
            completionHandler(resp)
        }
    }
    
    public static func addTrack(name: String, completionHandler: @escaping (String?) -> ()) -> () {
        let payload = ["name": "\(name)", "user": "\(currentUserID())"] as [String : Any]
        
        let loginurl = "\(ServerCommands.homeURL)/addTrack"
        Alamofire.request(loginurl, method: .post, parameters: payload).responseString {
            (response) in
            
            let resp = response.result.value
            completionHandler(resp)
        }
    }
    /*
     ServerCommands.addTrack(name: "apptest1") {resp in
     if(resp != nil){
     print(resp)
     }
     }
    */
    
    public static func createTrackWithLocations(name: String, locations: [CLLocation]) {
        ServerCommands.addTrack(name: "\(name)") {resp in
            if(resp != nil){
                print(resp)
                for location in locations {
                    ServerCommands.addLocation(latitude: Double(location.coordinate.latitude), longitude: Double(location.coordinate.longitude), tracknumber: Int(resp!)!) {resp in
                        if(resp != nil){
                            print(resp)
                        }
                    }
                }
            }
        }
    }
    /*
     ServerCommands.createTrackWithLocations(name: "apptest3", locations: locations)
     */
    
    public static func addLocation(latitude: Double, longitude: Double, tracknumber: Int, completionHandler: @escaping (String?) -> ()) -> () {
        let payload = ["latitude": "\(latitude)", "longitude": "\(longitude)", "tracknumber": "\(tracknumber)"] as [String : Any]
        
        let loginurl = "\(ServerCommands.homeURL)/addLocation"
        Alamofire.request(loginurl, method: .post, parameters: payload).responseString {
            (response) in
            
            let resp = response.result.value
            completionHandler(resp)
        }
    }
    
    public static func clearUser(completionHandler: @escaping () -> ()) -> () {
        Alamofire.request("\(homeURL)/logout")
        completionHandler()
    }
    
    public static func currentUserEmail() -> String {
        var (data, response, error) = URLSession.shared.synchronousDataTask(with: NSURL(string: "\(homeURL)/authStatus") as! URL)
        return NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
    }
    
    public static func currentUserID() -> String {
        var (data, response, error) = URLSession.shared.synchronousDataTask(with: NSURL(string: "\(homeURL)/currentUserID") as! URL)
        return NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
    }
}


extension URLSession {
    func synchronousDataTask(with url: URL) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let dataTask = self.dataTask(with: url) {
            data = $0
            response = $1
            error = $2
            
            semaphore.signal()
        }
        dataTask.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        return (data, response, error)
    }
}
