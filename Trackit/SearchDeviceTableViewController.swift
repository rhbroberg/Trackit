//
//  SearchDeviceTableViewController.swift
//  Trackit
//
//  Created by Richard Broberg on 1/13/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import UIKit
import CoreBluetooth

class SearchDeviceTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, BLEConfigurationManagerDelegate {

    @IBOutlet weak var table: UITableView!
    
    var bleManager : BLEConfigurationManager?
    var foundDeviceController : FoundDeviceViewController?

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: UIControlEvents.valueChanged)
        
        return refreshControl
    }()

    func handleRefresh(refreshControl: UIRefreshControl) {
        table.reloadData()
        refreshControl.endRefreshing()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        table!.delegate = self
        bleManager = BLEConfigurationManager()
        bleManager!.delegate = self
        table.addSubview(refreshControl)

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewDidDisappear(_ animated: Bool) {
        bleManager?.stopScanning()
    }

    override func viewDidAppear(_ animated: Bool) {
        // steal delegate back from FoundDeviceViewController
        bleManager?.delegate = self
        bleManager?.startScanning()
        table.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepare for segue")
        if segue.identifier! == "Show Found Device" {
            if let foundDevice = segue.destination as? FoundDeviceViewController {
                print("in found device")
                if let cell = sender as? SearchDeviceTableViewCell {
                    print("preparing for showing device, sender is \(sender) ")
                    bleManager?.selectedPeripheral = cell.peripheral
                }
                foundDevice.bleManager = bleManager
                foundDeviceController = foundDevice
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return (bleManager?.peripherals.count)!
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchDeviceCell", for: indexPath)
        
        if let cell = cell as? SearchDeviceTableViewCell {
            cell.peripheral = bleManager?.peripherals[indexPath.row].peripheral
            cell.name!.text = cell.peripheral?.name
        }

        return cell
    }

    // MARK: BLEConfigurationManagerDelegate
    func deviceDiscovered(peripheral: CBPeripheral) {
        table.reloadData()
    }

    func deviceDisappeared(peripheral: CBPeripheral) {
        table.reloadData()
    }

    func discoveryComplete() {
        print("looks like service/characteristic discovery is complete!")
        foundDeviceController?.retrieveAllCharacteristics()
    }
}
