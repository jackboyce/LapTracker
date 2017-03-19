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
    
    public static let homeURL: String = "http://45.55.180.218"
    
    public static func login(email: String, password: String, completionHandler: @escaping (String?) -> ()) -> () {
        let payload = ["email": "\(email)", "password": "\(password)"] as [String : Any]
        
        let loginurl = "\(ServerCommands.homeURL)/login"
        Alamofire.request(loginurl, method: .post, parameters: payload).responseString {
            (response) in
            
            let resp = response.result.value
            completionHandler(resp)
        }
    }
    
    public static func register(username: String, email: String, password: String, confirmPassword: String, completionHandler: @escaping (String?) -> ()) -> () {

        let payload = ["name": "\(username)", "email": "\(email)", "password": "\(password)", "password_confirmation": "\(confirmPassword)"] as [String : Any]
        
        let loginurl = "\(ServerCommands.homeURL)/register"
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
    
    public static func addTrackWithLocations(name: String, locations: [CLLocation], completionHandler: @escaping (String?) -> ()) -> () {
        ServerCommands.addTrack(name: "\(name)") { resp in
            if(resp != nil) {
                //print(resp)
                var sendString = ""
                for location in locations {
                    sendString += String(location.coordinate.latitude)
                    sendString += ","
                    sendString += String(location.coordinate.longitude)
                    sendString += "]["
                }
                print("Send the send string here")
                var string = "37.33523566,-122.03254863][37.3351212,-122.03256229][37.33503868,-122.03265072][37.33497737,-122.03281282][37.33494812,-122.0329212][37.33492222,-122.03304215][37.33489242,-122.03318372][37.33485843,-122.03334424][37.33482105,-122.03350886]["
                /*
                ServerCommands.addLocations(string: sendString, tracknumber: Int(resp!)!) { resp in
                    print(resp)
                }*/
                ServerCommands.addLocations(string: sendString, tracknumber: Int(resp!)!) { resp in
                    print(resp)
                }
                completionHandler(resp)
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
    
    public static func addLocations(string: String, tracknumber: Int, completionHandler: @escaping (String?) -> ()) -> () {
        var truncatedString = string.substring(to: string.index(string.endIndex, offsetBy: -2))
        print("Tracknumber: \(tracknumber)")
        print("String send: \(truncatedString)")
        let payload = ["locations": "\(truncatedString)", "tracknumber": "\(tracknumber)"] as [String : Any]
        let loginurl = "\(ServerCommands.homeURL)/addLocations"
        Alamofire.request(loginurl, method: .post, parameters: payload).responseString {
            (response) in
            
            let resp = response.result.value
            completionHandler(resp)
        }
    }
    
    public static func addTime(time: Double, tracknumber: Int, completionHandler: @escaping (String?) -> ()) -> () {
        let payload = ["time": "\(time)", "user": "\(currentUserID())", "tracknumber": "\(tracknumber)"] as [String : Any]
        
        let loginurl = "\(ServerCommands.homeURL)/addTime"
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
    
    public static func getLocationsForTrack(id: Int) -> [CLLocation] {
        var (data, response, error) = URLSession.shared.synchronousDataTask(with: NSURL(string: "\(homeURL)/getLocationsForTrack?id=\(id)") as! URL)
        let raw = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
        var rawLocations = raw.components(separatedBy: "][")
        rawLocations.removeLast()
        var locations = [CLLocation]()
        
        for location in rawLocations {
            let splitRawLocation = location.components(separatedBy: ",")
            locations.append(CLLocation(latitude: Double(splitRawLocation[1])!, longitude: Double(splitRawLocation[2])!))
        }
        return locations
    }
    
    public static func getTimesForTrack(id: Int) -> [(time: Double, username: String)] {
        var (data, response, error) = URLSession.shared.synchronousDataTask(with: NSURL(string: "\(homeURL)/getTimesForTrack?id=\(id)") as! URL)
        let raw = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
        var rawTimes = raw.components(separatedBy: "][")
        rawTimes.removeLast()
        var times = [(time: Double, username: String)]()
        
        for time in rawTimes {
            let splitRawTime = time.components(separatedBy: ",")
            times.append((time: Double(splitRawTime[1])!, username: splitRawTime[2]))
        }
        return times
    }
    
    public static func getTracks() -> [(id: Int, name: String, creator: String)] {
        var (data, response, error) = URLSession.shared.synchronousDataTask(with: NSURL(string: "\(homeURL)/getTracks") as! URL)
        let raw = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
        var rawTracks = raw.components(separatedBy: "][")
        rawTracks.removeLast()
        var tracks = [(id: Int, name: String, creator: String)]()
        
        for track in rawTracks {
            let splitRawTrack = track.components(separatedBy: ",")
            tracks.append((id: Int(splitRawTrack[0])!, name: splitRawTrack[1], creator: splitRawTrack[2]))
        }
        return tracks
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
