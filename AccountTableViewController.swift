//
//  AccountTableViewController.swift
//  Trackit
//
//  Created by Richard Broberg on 11/26/16.
//  Copyright © 2016 Stanford University. All rights reserved.
//

import UIKit

class AccountTableViewController: UITableViewController {

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userDefaults = UserDefaults.standard
        username!.text = userDefaults.string(forKey: "settings.account.username")
        password!.text = userDefaults.string(forKey: "settings.account.password")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewWillDisappear(_ animated: Bool) {
        let userDefaults = UserDefaults.standard
        
        userDefaults.set(username!.text, forKey: "settings.account.username")
        userDefaults.set(password!.text, forKey: "settings.account.password")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
