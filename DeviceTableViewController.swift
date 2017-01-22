//
//  DeviceTableViewController.swift
//  Trackit
//
//  Created by Richard Broberg on 1/4/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import UIKit
import CoreData

class DeviceTableViewController: UITableViewController, editDeviceViewControllerDelegate {

    var coreDataContainer : NSManagedObjectContext? =
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    var devices : [Device] = []

    func loadDevices() {
        coreDataContainer?.perform {
            self.devices = []
            print("loading devices")
            let request: NSFetchRequest<Device> = Device.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            request.sortDescriptors = [sortDescriptor]

            do {
                self.devices = try self.coreDataContainer!.fetch(request)
            } catch {
                print("fetch failed - \(error)")
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier! == "New Device" {
            if let newDevice = segue.destination as? ShowDeviceViewController {
                newDevice.delegate = self
            }
        }
        if (segue.identifier == "View Device") {
            if let viewDevice = segue.destination as? ShowDeviceViewController, let cell = sender as? DeviceTableViewCell {
                print("preparing for device name editing, sender is \(sender) ")
                viewDevice.device = cell.device
                viewDevice.delegate = self
            }
        }

        loadDevices()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Device", for: indexPath)

        if let cell = cell as? DeviceTableViewCell {
            cell.device = devices[indexPath.row]
            cell.name.text = devices[indexPath.row].name
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            print("deleting \(indexPath.row)")
            let device = devices[indexPath.row]
            coreDataContainer?.perform {
                self.coreDataContainer!.delete(device)
                self.devices.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                (UIApplication.shared.delegate as! AppDelegate).saveContext(context: self.coreDataContainer)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewDidAppear(_ animated: Bool) {
        loadDevices()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func specificDeviceChanged(device: Device)
    {
        loadDevices()
    }


}
