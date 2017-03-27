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
        errorLabel.text = ""
        save()
        print("Before clear: \(ServerCommands.currentUserEmail())")
        ServerCommands.clearUser() {
            print("After clear: \(ServerCommands.currentUserEmail())")
            ServerCommands.login(email: self.email.text!, password: self.password.text!) { resp in
                if(resp != nil){
                    //print(resp)
                    print("After login: \(ServerCommands.currentUserEmail())")
                    self.segueToMap()
                }
            }
        }
    }
    
    func segueToTracks() {
        let user = ServerCommands.currentUserEmail()
        
        if user == email.text! {
            let trackViewController = self.storyboard?.instantiateViewController(withIdentifier: "Tracks") as! TrackTableViewController
            self.navigationController?.pushViewController(trackViewController, animated: true)
        } else {
            errorLabel.text = "error"
        }
    }
    
    func segueToMap() {
        let user = ServerCommands.currentUserEmail()
        
        if user == email.text! {
            let mainMapViewController = self.storyboard?.instantiateViewController(withIdentifier: "MainMap") as! MainMapViewController
            self.navigationController?.pushViewController(mainMapViewController, animated: true)
        } else {
            errorLabel.text = "error"
        }
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


