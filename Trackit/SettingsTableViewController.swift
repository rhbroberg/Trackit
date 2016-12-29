//
//  SettingsTableViewController.swift
//  Trackit
//
//  Created by Richard Broberg on 12/28/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var version: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        registerReveal(menuButton: menuButton)

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        let versionString = (UIApplication.shared.delegate as! AppDelegate).getVersion()

        version!.text = versionString

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
