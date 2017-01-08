//
//  DeviceSearchViewController.swift
//  Trackit
//
//  Created by Richard Broberg on 1/7/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import UIKit
import CoreBluetooth

class DeviceSearchViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // non-global queue:
        // http://stackoverflow.com/questions/38390270/swift-choose-queue-for-bluetooth-central-manager
        bleManager = CBCentralManager(delegate: self, queue: nil)
        // Do any additional setup after loading the view.
    }

    var bleManager: CBCentralManager?
    var peripheral: CBPeripheral?

    @IBAction func searcj(_ sender: Any) {
        print("closing?")
        if peripheral != nil {
            bleManager?.cancelPeripheralConnection(peripheral!)
            peripheral = nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillDisappear(_ animated: Bool) {
    }

    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("ble state update: \(central.state)")

        if central.state == CBManagerState.poweredOn {
            print("searching...")
            central.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("ble not available (yet?)")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let device = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? NSString
        
        if device != nil {
            print("peripheral discovered: \(device!)")
        }
        if device?.contains("mytracker") == true {
            print("found mytracker")
            bleManager?.stopScan()
            self.peripheral = peripheral
            self.peripheral!.delegate = self

            bleManager?.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected to peripheral \(peripheral)")
        peripheral.discoverServices(nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("services discovered - errror? is \(error)")

        for service in peripheral.services! {
            let thisService = service as CBService

            print("discovering characteristics now for \(thisService)")
            peripheral.discoverCharacteristics(nil, for: thisService)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("discovered characteristics")
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            
            print("looking at characteristic \(thisCharacteristic)")
//            let junk = CBUUID(string: "a495ff21-c5b1-4b44-b512-1370f02d74de")
//            if thisCharacteristic.uuid == junk {
                self.peripheral?.setNotifyValue(true, for: thisCharacteristic)
//            }
            peripheral.readValue(for: characteristic)
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnected from peripheral")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("notify: peripheral wrote value: \(characteristic)")
    } 

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("notify: peripheral updated value: \(characteristic)")

        if let data = characteristic.value {
            var bytes = Array(repeating: 0 as UInt8, count:data.count) //MemoryLayout.size(ofValue: count)/MemoryLayout<UInt8>.size)
    
            var myint : UInt16 = 0
            if data.count > 1 {
                data.copyBytes(to: &bytes, count:data.count)
                let data16 = bytes.map { UInt16($0) }
                myint = 256 * data16[1] + data16[0]
            }

            let s = String(bytes: data, encoding: String.Encoding.utf8)
            print("string version of value is \(s), int is \(myint)")
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
