//
//  ShowDeviceViewController.swift
//  Trackit
//
//  Created by Richard Broberg on 1/4/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import UIKit
import CoreData

class ShowDeviceViewController: UIViewController {

    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var id: UILabel!
    @IBOutlet weak var firmwarePresent: UILabel!
    @IBOutlet weak var firmwareAvailable: UILabel!
    
    @IBAction func updateFirmware(_ sender: Any) {
    }

    weak var delegate : editDeviceViewControllerDelegate?
    var device : Device?
    var coreDataContainer : NSManagedObjectContext? =
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()

        if let device = device {
            name!.text = device.name
        }
        else {
            name!.text = "undefined device"
        }
        
        // allow any tap in view to dismiss keyboard
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ShowDeviceViewController.handleTap))
        self.view.addGestureRecognizer(gestureRecognizer)
    }

    func handleTap(gestureRecognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // it's probably time to move these behaviors into the subclasses rather than all the switch-case-ing
        // first case: geofence added from scratch
        if let device = device {
            device.name = name!.text
        }
        else {
            if let device = NSEntityDescription.insertNewObject(forEntityName: "Device", into: self.coreDataContainer!) as? Device {
                device.name = self.name!.text
                self.device = device
            }
        }
        (UIApplication.shared.delegate as! AppDelegate).saveContext(context: self.coreDataContainer)

        // propagate changed object to delegate
        delegate?.specificDeviceChanged(device: device!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

protocol editDeviceViewControllerDelegate : class {
    func specificDeviceChanged(device: Device)
}
