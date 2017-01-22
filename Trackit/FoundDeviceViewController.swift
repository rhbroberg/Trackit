//
//  DeviceSearchViewController.swift
//  Trackit
//
//  Created by Richard Broberg on 1/7/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import UIKit
import CoreData
import CoreBluetooth

class FoundDeviceViewController: UIViewController, BLEConfigurationManagerDelegate {

    @IBOutlet weak var imsi: UILabel!
    @IBOutlet weak var icci: UILabel!
    @IBOutlet weak var imei: UILabel!
    
    @IBOutlet weak var name: UITextField!
    
    @IBOutlet weak var software: UILabel!
    @IBOutlet weak var version: UILabel!
    @IBOutlet weak var firmware: UILabel!
    
    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBAction func add(_ sender: Any) {
        // turn on spinner?
        print("time to add to db")
        bleManager!.delegate = self
        activity!.startAnimating()

        self.coreDataContainer?.perform {
            if let device = NSEntityDescription.insertNewObject(forEntityName: "Device", into: self.coreDataContainer!) as? Device {
                device.name = self.name!.text!
                device.software = self.software!.text
                device.version = self.version!.text
                device.firmware = self.firmware!.text
                device.imei = self.imei!.text
                device.icci = self.icci!.text
                device.imsi = self.imsi!.text
                device.color = "red" // as good a default as any
                (UIApplication.shared.delegate as! AppDelegate).saveContext(context: self.coreDataContainer)
            }
        }
        
        if self.originalName != self.name!.text {
            _ = bleManager!.writeStringCharacteristic(name: "app.name", value: name!.text!) { () -> Void in
                DispatchQueue.main.async {
                    print("remote ble name change accepted")

                    _ = self.bleManager!.writeInt16Characteristic(name: "app.reboot", value: 1) { () -> Void in
                        DispatchQueue.main.async {
                            print("reboot command accepted, starting to scan again")
                            self.bleManager?.startScanning()
                        }
                    }
                }
            }
        }
        else {
            print("no name change, just added - time to leave")
            activity!.stopAnimating()
        }
    }

    var originalName : String?

    var coreDataContainer : NSManagedObjectContext? =
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    func retrieveAllCharacteristics() {
        print("peeking")
        _ = bleManager!.readStringCharacteristic(name: "sim.IMSI") { (value) -> Void  in
            print("IMSI \(value)")
            DispatchQueue.main.async {
                self.imsi!.text = value
            }
        }
        
        _ = bleManager!.readStringCharacteristic(name: "sim.IMEI") { (value) -> Void  in
            print("IMEI \(value)")
            DispatchQueue.main.async {
                self.imei!.text = value
            }
        }
        
        _ = bleManager!.readStringCharacteristic(name: "sim.ICCI") { (value) -> Void  in
            print("ICCI \(value)")
            DispatchQueue.main.async {
                self.icci!.text = value
            }
        }
        
        _ = bleManager!.readStringCharacteristic(name: "version.name") { (value) -> Void in
            DispatchQueue.main.async {
                self.software!.text = "\(value)"
            }
        }
        
        _ = bleManager!.readStringCharacteristic(name: "version.version") { (value) -> Void in
            DispatchQueue.main.async {
                self.version!.text = "\(value)"
            }
        }
        
        _ = bleManager!.readStringCharacteristic(name: "version.firmware") { (value) -> Void in
            DispatchQueue.main.async {
                self.firmware!.text = "\(value)"
            }
        }
    }

    var bleManager : BLEConfigurationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        name!.text = bleManager?.selectedDevice?.peripheral?.name
        originalName = name!.text

        if (bleManager?.selectedDevice?.allServicesDiscovered())! {
            print("looks like we already have all the data we need, strangely")
            retrieveAllCharacteristics()
        }

        // allow any tap in view to dismiss keyboard
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(FoundDeviceViewController.handleTap))
        self.view.addGestureRecognizer(gestureRecognizer)
    }

    func handleTap(gestureRecognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillDisappear(_ animated: Bool) {
        bleManager?.disconnectFromPeripheral()
    }

    // MARK: BLEConfigurationManagerDelegate
    func deviceDiscovered(peripheral: CBPeripheral) {
        print("rediscovered \(peripheral)")
        if peripheral.name == originalName {
            print("and i see our old friend \(originalName) is back")
            print("now we connect")
            bleManager?.selectedPeripheral = peripheral
            // now wait until connect callback
        }
    }

    func deviceDisappeared(peripheral: CBPeripheral) {
    }

    func discoveryComplete() {
        print("looks like service/characteristic discovery is complete!")
        activity!.stopAnimating()
        // leave subview now
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
