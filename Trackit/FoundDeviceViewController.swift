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
    @IBOutlet weak var progress: UIProgressView!

    // MARK: firmware update
    var currentUploadHunk = 0
    let hunksize = 160
    var firmwareImage : Data?
    var firmwareIterator : Data.Iterator?
    var hunkNotifier : NSObjectProtocol?

    private func digest(input : NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hashValue = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hashValue)
        return NSData(bytes: hashValue, length: digestLength)
    }

    // this cryptic hunk of cryptography code comes from
    //  http://stackoverflow.com/questions/39921117/sha-256-encryption-syntax-error-in-swift-3-0
    func sha256(data: Data?) -> Data? {
        guard let messageData = data else { return nil; }
        var digestData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_SHA256(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        return digestData
    }

    func writeVerification() {
        let shaData = sha256(data: firmwareImage)
        let shaHex = shaData?.map { String(format: "%02hhx", $0) }.joined()
        
        if let shaHex = shaHex {
            let nsval = NSString(string: shaHex)
            let checksum = Data(bytes: nsval.utf8String!, count: nsval.length)
            print("sending verification checksum \(shaHex)")
            
            _ = bleManager!.writeBytesCharacteristic(name: "firmware.verification", data: checksum) { () -> Void in
                DispatchQueue.main.async {
                    print("wrote verification")
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "verify done"), object: nil, userInfo: nil)
                }
            }
        }
        else {
            print("cannot compute checksum, nothing to send!")
            // probably indicate failure to user with modal here
        }
    }
    
    func hunkUploaded(notification: Notification) -> Void {

        if let firmwareImage = firmwareImage {
            print("uploaded \(currentUploadHunk) out of \(firmwareImage.count / hunksize)")

            if currentUploadHunk < (firmwareImage.count / hunksize) {
                currentUploadHunk = currentUploadHunk + 1
                writeHunk(which: currentUploadHunk)
                let maxHunks = Float(firmwareImage.count) / Float(hunksize)
                let percentDone = Float(currentUploadHunk) / maxHunks
                progress.setProgress(percentDone, animated: true)
            }
            else
            {
                progress.isHidden = true
                print("done uploading all hunks")
                writeVerification()
                NotificationCenter.default.removeObserver(hunkNotifier!)
            }
        }
    }

    func writeHunk(which: Int) {
        let start = hunksize * which
        var  end = start + hunksize
        if end > (firmwareImage?.count)! {
            end = (firmwareImage?.count)!
        }

        let hunk : Data = (firmwareImage?.subdata(in: start..<end))!
        
        _ = bleManager!.writeBytesCharacteristic(name: "firmware.image", data: hunk) { () -> Void in
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "hunk done"), object: nil, userInfo:["which":which])
            }
        }
    }

    @IBAction func upload(_ sender: Any) {
        print("uploading now")
        progress.isHidden = false
        progress.setProgress(0.0, animated: false)
        currentUploadHunk = 0
        let nc = NotificationCenter.default
        // remove prior notifier if it did not complete sucessfully
        if let hunkNotifier = hunkNotifier {
            nc.removeObserver(hunkNotifier)
        }

        hunkNotifier = nc.addObserver(forName: NSNotification.Name(rawValue: "hunk done"), object:nil, queue:nil, using:hunkUploaded)

        if let firmwareAsset = NSDataAsset(name: "firmware") {
            firmwareImage = firmwareAsset.data
            firmwareIterator = firmwareImage?.makeIterator()
            print("found firmware size \(firmwareImage?.count) bytes, how to specify version?")
        }

        writeHunk(which: 0)
    }

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

        progress.isHidden = true
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
        NotificationCenter.default.removeObserver(self)
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

        // back to whence we came; not perfect yet, it would be nice to wait until the 
        // modal pop-up appeared trying to pair - or else disconnect and connect again
        // using new name here, to avoid long discovery delay in search view
        if let myNavigationController = self.parent as? UINavigationController {
            myNavigationController.popViewController(animated: true)
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
