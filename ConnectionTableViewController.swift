//
//  ConnectionTableViewController.swift
//  Trackit
//
//  Created by Richard Broberg on 11/26/16.
//  Copyright © 2016 Stanford University. All rights reserved.
//

import UIKit

class ConnectionTableViewController: UITableViewController {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var server: UITextField!
    @IBOutlet weak var port: UITextField!
    @IBOutlet weak var keepAlive: UITextField!
    @IBOutlet weak var isSecure: UISwitch!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        registerReveal(menuButton: menuButton)
        let userDefaults = UserDefaults.standard
        server!.text = userDefaults.string(forKey: "settings.connection.server")
        port!.text = userDefaults.string(forKey: "settings.connection.port")
        keepAlive!.text = userDefaults.string(forKey: "settings.connection.keepAlive")
        isSecure!.isOn = userDefaults.bool(forKey: "settings.connection.isSecure")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewWillDisappear(_ animated: Bool) {
        let userDefaults = UserDefaults.standard

        userDefaults.set(server!.text, forKey: "settings.connection.server")
        userDefaults.set(port!.text, forKey: "settings.connection.port")
        userDefaults.set(keepAlive!.text, forKey: "settings.connection.keepAlive")
        userDefaults.set(isSecure!.isOn, forKey: "settings.connection.isSecure")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

}
