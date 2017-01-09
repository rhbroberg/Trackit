//
//  DeviceSearchViewController.swift
//  Trackit
//
//  Created by Richard Broberg on 1/7/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import UIKit

class DeviceSearchViewController: UIViewController {

    @IBAction func peek(_ sender: Any) {
        print("peeking")
        bleManager!.readStringCharacteristic(name: "gsm.proxyIP") { (value) -> Void  in
            print("this is my closure, i see \(value)")
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
