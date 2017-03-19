//
//  RegisterViewController.swift
//  LapTracker
//
//  Created by Jack Boyce on 1/29/17.
//  Copyright © 2017 Jack Boyce. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var confirmationPassword: UITextField!
    @IBOutlet weak var statusBox: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        statusBox.text = ""
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func register(_ sender: Any) {
        print("Register")
        //sendData()
        ServerCommands.clearUser {
            ServerCommands.register(username: self.username.text!, email: self.email.text!, password: self.password.text!, confirmPassword: self.confirmationPassword.text!) { resp in
                print(resp)
                self.statusBox.text = "Account created"
            }
        }
        //_ = navigationController?.popViewController(animated: true)
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
