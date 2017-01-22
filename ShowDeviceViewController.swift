//
//  ShowDeviceViewController.swift
//  Trackit
//
//  Created by Richard Broberg on 1/4/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import UIKit
import CoreData

class ShowDeviceViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {


    @IBOutlet weak var firmwareAvailable: UILabel!
    @IBOutlet weak var firmwarePresent: UILabel!
    
    @IBAction func updateFirmware(_ sender: Any) {
    }
    @IBAction func defaults(_ sender: Any) {
    }
    @IBAction func restart(_ sender: Any) {
    }
    @IBAction func remove(_ sender: Any) {
    }

    
    @IBOutlet weak var colorPicker: UIPickerView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var imsi: UILabel!
    @IBOutlet weak var imei: UILabel!
    @IBOutlet weak var system: UILabel!
    @IBOutlet weak var icci: UILabel!

    weak var delegate : editDeviceViewControllerDelegate?
    var device : Device?
    var coreDataContainer : NSManagedObjectContext? =
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var selectedColor : String = ""
    var pickerChoices : [String] = ["red", "yellow", "blue", "orange", "magenta", "green", "purple"]

    override func viewDidLoad() {
        super.viewDidLoad()

        if let device = device,
            let color = device.color {
            selectedColor = color
            name!.text = device.name
            imei!.text = device.imei
            imsi!.text = device.imsi
            icci!.text = device.icci
            firmwarePresent!.text = device.version
            system!.text = device.firmware
        }
        else {
            name!.text = "undefined device"
            selectedColor = "red"
        }
        colorPicker.delegate = self
        colorPicker.dataSource = self
        colorPicker.selectRow(pickerChoices.index(of: selectedColor)!, inComponent: 0, animated: false)

        // allow any tap in view to dismiss keyboard
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ShowDeviceViewController.handleTap))
        self.view.addGestureRecognizer(gestureRecognizer)
    }

    func handleTap(gestureRecognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let device = device {
            device.name = name!.text
            device.color = selectedColor
        }
        else {
            if let newDevice = NSEntityDescription.insertNewObject(forEntityName: "Device", into: self.coreDataContainer!) as? Device {
                newDevice.name = self.name!.text
                newDevice.color = selectedColor
                device = newDevice
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

    // MARK: - UIPickerView
    // The number of columns of data
    func numberOfComponents(in: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerChoices.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerChoices[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("selected \(row)")
        selectedColor = pickerChoices[row]
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
