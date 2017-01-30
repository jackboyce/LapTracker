//
//  ServerCommands.swift
//  LapTracker
//
//  Created by Jack Boyce on 1/30/17.
//  Copyright © 2017 Jack Boyce. All rights reserved.
//

import Foundation
import Alamofire

class ServerCommands {
    
    public static let homeURL: String = "http://localhost:8000"
    
    /*
    public static func login(email: String, password: String) {
        //URLSession.shared.synchronousDataTask(with: NSURL(string: "\(homeURL)/login" + "?email=\(email)&password=\(password)") as! URL)
        
        var request = URLRequest(url: URL(string: "\(homeURL)/login")!)
        request.httpMethod = "POST"
        let postString = "email=\(email)&password=\(password)"
        print(postString)
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            //print("responseString = \(responseString)")
        }
        task.resume()
    }*/
    
    public static func login(email: String, password: String, completionHandler: @escaping (String?) -> ()) -> () {
        let payload = ["email": "\(email)", "password": "\(password)"] as [String : Any]
        
        let loginurl = "\(ServerCommands.homeURL)/login"
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
    
    public static func currentUser() -> String {
        var (data, response, error) = URLSession.shared.synchronousDataTask(with: NSURL(string: "\(homeURL)/authStatus") as! URL)
        return NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
    }
    
    func sendData() {
        /*
         var request = URLRequest(url: URL(string: "http://localhost:8000/login")!)
         request.httpMethod = "POST"
         let postString = "email=\(email.text!)&password=\(password.text!)"
         print(postString)
         request.httpBody = postString.data(using: .utf8)
         let task = URLSession.shared.dataTask(with: request) { data, response, error in
         guard let data = data, error == nil else {                                                 // check for fundamental networking error
         print("error=\(error)")
         return
         }
         
         if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
         print("statusCode should be 200, but is \(httpStatus.statusCode)")
         print("response = \(response)")
         }
         
         let responseString = String(data: data, encoding: .utf8)
         //print("responseString = \(responseString)")
         }
         task.resume()*/
        
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
