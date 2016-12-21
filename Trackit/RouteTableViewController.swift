//
//  RouteTableViewController.swift
//  Trackit
//
//  Created by Richard Broberg on 12/2/16.
//  Copyright © 2016 Stanford University. All rights reserved.
//

import UIKit
import CoreData

class RouteTableViewController: UITableViewController
{
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var addRoute: UIBarButtonItem!

    @IBAction func addRoutePressed(_ sender: Any) {
        print("add a new route")

        coreDataContainer?.perform {
            let routeCount = try? self.coreDataContainer!.count(for: NSFetchRequest(entityName: "Route"))
            print("\(routeCount) existing routes")
            let newRouteName = "route \(routeCount!)"

            if let route = NSEntityDescription.insertNewObject(forEntityName: "Route", into: self.coreDataContainer!) as? Route {
                route.name = newRouteName
                route.startDate = NSDate.init()
                route.isVisible = true
                self.saveContext()
                (UIApplication.shared.delegate as! AppDelegate).currentRoute = route
            }
        }
        getAllRoutes()
    }

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

    var routes = [Route]() {
        didSet {
        }
    }

   var coreDataContainer : NSManagedObjectContext? =
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()

        registerReveal(menuButton: menuButton)
        getAllRoutes()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    func getAllRoutes() {
        coreDataContainer?.perform {
            self.routes = []
            print("loading routes")
            let request: NSFetchRequest<Route> = Route.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            request.sortDescriptors = [sortDescriptor]

            do {
                self.routes = try self.coreDataContainer!.fetch(request)
                print("i see \(self.routes.count) routes")
            } catch {
                print("fetch failed, bummer")
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    // MARK: UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RouteCell", for: indexPath)

        if let cell = cell as? RouteTableViewCell {
            let route = routes[indexPath.row]
            cell.entries.text = "\(route.locations!.count)"
            cell.name?.text = route.name!
            cell.isVisible.isOn = route.isVisible
            let dateFormat = DateFormatter()
            dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormat.timeZone = TimeZone.autoupdatingCurrent
            cell.created?.text = dateFormat.string(for: route.startDate!)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Section \(section)"
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            print("deleting \(indexPath.row)")
            let route = routes[indexPath.row]
            coreDataContainer?.perform {
                self.coreDataContainer!.delete(route)
                self.routes.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                self.saveContext()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
