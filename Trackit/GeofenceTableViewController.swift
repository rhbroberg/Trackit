//
//  GeofenceViewController.swift
//  Trackit
//
//  Created by Richard Broberg on 12/22/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//

import UIKit
import CoreData

class GeofenceTableViewController: UITableViewController, EditGeofenceViewControllerDelegate {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerReveal(menuButton: menuButton)
        
        loadGeofence()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepare for segue")
        if segue.identifier! == "New Geofence" {
            if let editGeofence = segue.destination as? EditGeofenceViewController {
                print("in geofence edit land")
                editGeofence.delegate = self
            }
        }
        if (segue.identifier == "Edit Geofence") {
            if let geofenceEditor = segue.destination as? EditGeofenceViewController, let cell = sender as? GeofenceTableViewCell {
                print("preparing for gence name editing, sender is \(sender) ")
                geofenceEditor.geofence = cell.geofence
            }
        }

        loadGeofence()
    }

    func loadGeofence() {
        coreDataContainer?.perform {
            self.fences = []
            print("loading geofence")
            let request: NSFetchRequest<Geofence> = Geofence.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            request.sortDescriptors = [sortDescriptor]
            
            do {
                self.fences = try self.coreDataContainer!.fetch(request)
            } catch {
                print("fetch failed - \(error)")
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - EditGeofenceViewControllerDelegate
    func specificGeofenceChanged(newFence: Geofence) {
        print("got geofence in tableView: \(newFence)")
        loadGeofence()
    }

    // MARK: - common code, consolidate me
    
    var coreDataContainer : NSManagedObjectContext? =
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    func saveContext() {
        if (coreDataContainer?.hasChanges)! {
            do {
                print("saving data now")
                try coreDataContainer?.save()
            }
                
            catch let error {
                print("Core data error: \(error)")
            }
        }
    }

    var fences: [Geofence] = []

    // MARK: - UITableViewController
    // MARK: UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fences.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GeofenceCell", for: indexPath)
        
        if let cell = cell as? GeofenceTableViewCell {
            cell.geofence = fences[indexPath.row]
            cell.name.text = fences[indexPath.row].name
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            print("deleting \(indexPath.row)")
            let geofence = fences[indexPath.row]
            coreDataContainer?.perform {
                self.coreDataContainer!.delete(geofence)
                self.fences.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                self.saveContext()
            }
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
