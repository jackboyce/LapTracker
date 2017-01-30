//
//  LoginViewController.swift
//  LapTracker
//
//  Created by Jack Boyce on 1/29/17.
//  Copyright © 2017 Jack Boyce. All rights reserved.
//

import UIKit
import Locksmith

class LoginViewController: UIViewController {
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var rememberSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let dictionary = Locksmith.loadDataForUserAccount(userAccount: "LapTracker") {
            email.text = dictionary["email"] as! String?
            password.text = dictionary["password"] as! String?
        } else {
            do{
                try Locksmith.saveData(data:["email": "", "password": ""], forUserAccount: "LapTracker")
            } catch {
                print("error")
            }
        }
        //Load the remember me data into the text boxes
        rememberSwitch.setOn(UserDefaults.standard.bool(forKey: "Switch"), animated: false)
        
        //Let the keyboard be dismissed by tapping anywhere not on the keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sendData() {
        
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
        task.resume()
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func save() {
        if rememberSwitch.isOn {
            do {
                try Locksmith.updateData(data: ["email": email.text!, "password": password.text!], forUserAccount: "LapTracker")
            } catch {
                print("error")
            }
        } else {
            do {
                try Locksmith.deleteDataForUserAccount(userAccount: "LapTracker")
            } catch {
                print("error")
            }
        }
        UserDefaults.standard.set(rememberSwitch.isOn, forKey: "Switch")
    }
    
    @IBAction func login(_ sender: Any) {
        save()
        sendData()
        
        var (data, response, error) = URLSession.shared.synchronousDataTask(with: NSURL(string: "http://localhost:8000/authStatus") as! URL)
        var loggedIn = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
        print(loggedIn)
        
        if loggedIn != "none" {
            let trackViewController = self.storyboard?.instantiateViewController(withIdentifier: "Tracks") as! TrackTableViewController
            self.navigationController?.pushViewController(trackViewController, animated: true)
        } else {
            errorLabel.text = "error"
        }
        /*
        if loggedIn == email.text! {
            let trackViewController = self.storyboard?.instantiateViewController(withIdentifier: "Tracks") as! TrackTableViewController
            self.navigationController?.pushViewController(trackViewController, animated: true)
        } else if loggedIn != "none" {
            var (data, response, error) = URLSession.shared.synchronousDataTask(with: NSURL(string: "http://localhost:8000/logout") as! URL)
        }*/
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

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
