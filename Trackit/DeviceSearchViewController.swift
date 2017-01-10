//
//  DeviceSearchViewController.swift
//  Trackit
//
//  Created by Richard Broberg on 1/7/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import UIKit

class DeviceSearchViewController: UIViewController {

    @IBOutlet weak var server: UILabel!
    @IBOutlet weak var imsi: UILabel!
    @IBOutlet weak var icci: UILabel!
    @IBOutlet weak var imei: UILabel!
    
    
    @IBOutlet weak var rxlevel: UILabel!
    @IBOutlet weak var bsic: UILabel!
    @IBOutlet weak var towerid: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var version: UILabel!
    @IBOutlet weak var firmware: UILabel!
    
    @IBAction func peek(_ sender: Any) {
        print("peeking")
        _ = bleManager!.readStringCharacteristic(name: "mqtt.server") { (value) -> Void  in
            print("server \(value)")
            DispatchQueue.main.async {
                self.server!.text = value
            }
        }

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

        _ = bleManager!.readInt16Characteristic(name: "cell.rxlev") { (value) -> Void in
            print("rxlevel is \(value)")
            DispatchQueue.main.async {
                self.rxlevel!.text = "\(value)"
            }
        }

        _ = bleManager!.readInt16Characteristic(name: "cell.bsic") { (value) -> Void in
            print("bsic is \(value)")
            DispatchQueue.main.async {
                self.bsic!.text = "\(value)"
            }
        }

        _ = bleManager!.readStringCharacteristic(name: "cell.towerid") { (value) -> Void in
            print("towerid is \(value)")
            DispatchQueue.main.async {
                self.towerid!.text = "\(value)"
            }
        }

        _ = bleManager!.readStringCharacteristic(name: "version.name") { (value) -> Void in
            DispatchQueue.main.async {
                self.name!.text = "\(value)"
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        bleManager = BLEConfigurationManager()
        // Do any additional setup after loading the view.
    }
    var bleManager : BLEConfigurationManager?

    @IBAction func searcj(_ sender: Any) {
        print("closing?")
        if bleManager?.foundDevice?.peripheral != nil {
            bleManager?.cbManager?.cancelPeripheralConnection((bleManager?.foundDevice!.peripheral!)!)
            bleManager?.foundDevice = nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillDisappear(_ animated: Bool) {
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
