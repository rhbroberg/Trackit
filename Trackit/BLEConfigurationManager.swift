//
//  BLEConfigurationManager.swift
//  Trackit
//
//  Created by Richard Broberg on 1/8/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import UIKit
import CoreBluetooth

struct ExpiringPeripheral {
    let peripheral : CBPeripheral
    var lastSeen : Date
}

class BLEConfigurationManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private(set) var selectedDevice : BLEDevice?

    var selectedPeripheral : CBPeripheral? {
        willSet {
            if newValue != nil {
                stopScanning()
                cbManager?.connect(newValue!, options: nil)
                selectedDevice = BLEDevice(peripheral: newValue, delegate: self)
            }
        }
    }

    var expirationTimer : Timer?
    var peripherals : [ExpiringPeripheral] = []
    var byUUID : [CBUUID : String]
    var properties : [String : bleConfiguration]
    var cbManager: CBCentralManager?
    var delegate : BLEConfigurationManagerDelegate?

    // keep track of outstanding services and characteristics in flight, so we know when we're fully initialized
    // alternatively services could be retrieved lazy-ly
    override init() {
        byUUID = [:]
        properties = [:]

        super.init()

        _ = registerConfig(name: "gsm.proxyIP", uuidHex: uuids.proxyIP_uuid, size: 32, storageType: .string)
        _ = registerConfig(name: "gsm.apn", uuidHex: uuids.apn_uuid, size: 32, storageType: .string)
        _ = registerConfig(name: "gsm.proxyPort", uuidHex: uuids.proxyPort_uuid, size: 32, storageType: .int64)
        
        _ = registerConfig(name: "mqtt.key", uuidHex: uuids.aioKey_uuid, size: 32, storageType: .string)
        _ = registerConfig(name: "mqtt.server", uuidHex: uuids.aioServer_uuid, size: 32, storageType: .string)
        _ = registerConfig(name: "mqtt.username", uuidHex: uuids.aioUsername_uuid, size: 32, storageType: .string)
        _ = registerConfig(name: "mqtt.port", uuidHex: uuids.aioPort_uuid, size: 32, storageType: .int64)
        
        _ = registerConfig(name: "sim.IMSI", uuidHex: uuids.simIMSI_uuid, size: 32, storageType: .string)
        _ = registerConfig(name: "sim.IMEI", uuidHex: uuids.simIMEI_uuid, size: 32, storageType: .string)
        _ = registerConfig(name: "sim.ICCI", uuidHex: uuids.simICCI_uuid, size: 32, storageType: .string)
        
        _ = registerConfig(name: "post.delay", uuidHex: uuids.gpsDelay_uuid, size: 32, storageType: .int64)

        _ = registerConfig(name: "cell.arfcn", uuidHex: uuids.arfcn_uuid, size: 32, storageType: .int32)
        _ = registerConfig(name: "cell.bsic", uuidHex: uuids.bsic_uuid, size: 32, storageType: .int16)
        _ = registerConfig(name: "cell.rxlev", uuidHex: uuids.rxlev_uuid, size: 32, storageType: .int16)
        _ = registerConfig(name: "cell.towerid", uuidHex: uuids.towerId_uuid, size: 32, storageType: .string)
        
        _ = registerConfig(name: "version.name", uuidHex: uuids.name_uuid, size: 32, storageType: .string)
        _ = registerConfig(name: "version.version", uuidHex: uuids.version_uuid, size: 32, storageType: .string)
        _ = registerConfig(name: "version.firmware", uuidHex: uuids.firmware_uuid, size: 32, storageType: .string)
        
        _ = registerConfig(name: "motion.delay", uuidHex: uuids.motionDelay_uuid, size: 32, storageType: .int64)

        // non-global queue:
        // http://stackoverflow.com/questions/38390270/swift-choose-queue-for-bluetooth-central-manager
        cbManager = CBCentralManager(delegate: self, queue: nil)
    }

    deinit {
        print("deinit for BLEConfigurationManager")
        stopScanning()
    }

    func startScanning() {
        if cbManager?.state == CBManagerState.poweredOn {
            peripherals = []
            cbManager?.scanForPeripherals(withServices: nil, options: nil)
            
            if expirationTimer == nil {
                expirationTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { _ in
                    self.reapExpiredAndScanAgain()
                }
                )
            }
        }
    }

    func stopScanning() {
        expirationTimer?.invalidate()
        expirationTimer = nil
        cbManager?.stopScan()
    }
    
    func disconnectFromPeripheral() {
        if selectedDevice?.peripheral != nil {
            cbManager?.cancelPeripheralConnection(selectedDevice!.peripheral!)
            selectedDevice = nil
        }
        startScanning()
    }

    func registerConfig(name: String, uuidHex: [UInt8], size: Int, storageType: bleConfiguration.StorageImplementation) -> bleConfiguration {
        let uuid = uuids.convert(from: uuidHex)
        properties[name] = bleConfiguration(uuid: uuid, size: size, storageType: storageType, value: nil)
        byUUID[uuid] = name
        
        return properties[name]!
    }
    
    func readStringCharacteristic(name : String, handler: @escaping (_ value: String) -> Void) -> Bool {
        if let thisCharacteristic = properties[name] {
            if let BLECharacteristic = selectedDevice?.findCharacteristic(uuid: thisCharacteristic.uuid) as? bleStringCharacteristic {
                BLECharacteristic.readHandler = handler
                selectedDevice?.peripheral?.readValue(for: BLECharacteristic.characteristic)
                return true
            }
        }
        return false
    }

    func readInt16Characteristic(name : String, handler: @escaping (_ value: UInt16) -> Void) -> Bool {
        if let thisCharacteristic = properties[name] {
            if let BLECharacteristic = selectedDevice?.findCharacteristic(uuid: thisCharacteristic.uuid) as? bleIntCharacteristic {
                BLECharacteristic.readHandler = handler
                selectedDevice?.peripheral?.readValue(for: BLECharacteristic.characteristic)
                return true
            }
        }
        return false
    }
    
    func reapExpiredAndScanAgain() {
        for recentPeripheral in peripherals {
            let howOld = recentPeripheral.lastSeen.timeIntervalSinceNow
            print("peripheral \(recentPeripheral) is \(howOld)")
            if howOld < -10 {
                print("peripheral \(recentPeripheral) is expiring")
                if let existing = peripherals.index(where: { $0.peripheral.name == recentPeripheral.peripheral.name }) {
                    peripherals.remove(at: existing)
                    delegate?.deviceDisappeared(peripheral: recentPeripheral.peripheral)
                }
            }
        }
        cbManager?.scanForPeripherals(withServices: nil, options: nil)
    }

    func addOrUpdateDevice(peripheral: CBPeripheral) {
        let now = Date()
        if let existing = peripherals.index(where: { $0.peripheral.name == peripheral.name })
        {
            print("updating timestamp on \(peripherals[existing])")
            peripherals[existing].lastSeen = now
        }
        else {
            print("adding new \(peripheral)")
            peripherals.append(ExpiringPeripheral(peripheral: peripheral, lastSeen: Date()))
            peripherals.sort {
                guard let left = $0.peripheral.name, let right = $1.peripheral.name else {
                    return false
                }
                return left < right
            }
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("ble state update: \(central.state)")

        if central.state == CBManagerState.poweredOn {
            print("searching...")
            startScanning()
        } else {
            print("ble not available (yet?)")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("central manager did discover peripheral...")
        print("advertisements are: \(advertisementData)")

        if let device = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? NSString {
            print("peripheral discovered: \(device)")

            if device.contains("mytracker-") == true {
                addOrUpdateDevice(peripheral: peripheral)
                delegate?.deviceDiscovered(peripheral: peripheral)
            }
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
            
            selectedDevice?.registerService(service: thisService)
            peripheral.discoverCharacteristics(nil, for: thisService)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let serviceTree = selectedDevice?.findService(service: service) {
            for characteristic in service.characteristics! {
                let thisCharacteristic = characteristic as CBCharacteristic
                
                if let which = byUUID[thisCharacteristic.uuid] {
                    serviceTree.registerCharacteristic(characteristic: thisCharacteristic, storageType: (properties[which]!.storageType))
                }
                
                self.selectedDevice?.peripheral?.setNotifyValue(true, for: thisCharacteristic)
            }
        } else {
            print("**** danger will robinson: can't find service \(service.uuid)")
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
        
        selectedDevice?.findCharacteristic(uuid: characteristic.uuid)?.parse()
    }
}

protocol BLEConfigurationManagerDelegate : class {
    func deviceDiscovered(peripheral: CBPeripheral)
    func deviceDisappeared(peripheral: CBPeripheral)
}
