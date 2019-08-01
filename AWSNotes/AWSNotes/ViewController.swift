//
//  ViewController.swift
//  AWSNotes
//
//  Created by McKinney family  on 7/31/19.
//  Copyright © 2019 FasTek Technologies. All rights reserved.
//

import UIKit
import AWSAuthUI
import AWSAuthCore

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !AWSSignInManager.sharedInstance().isLoggedIn{
            AWSAuthUIViewController.presentViewController(with: self.navigationController!, configuration: nil) { (provider, error) in
                if error == nil {
                    print("success")
                }
                else {
                    print(error?.localizedDescription ?? "no value")
                }
            }
        }
    }


}

