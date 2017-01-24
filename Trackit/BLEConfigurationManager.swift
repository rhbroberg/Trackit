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
    var peripherals : [ExpiringPeripheral]
    var byUUID : [CBUUID : String]
    var properties : [String : bleConfiguration]
    var cbManager: CBCentralManager?
    var delegate : BLEConfigurationManagerDelegate?

    // keep track of outstanding services and characteristics in flight, so we know when we're fully initialized
    // alternatively services could be retrieved lazy-ly
    override init() {
        byUUID = [:]
        properties = [:]
        peripherals = []

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
        
        _ = registerConfig(name: "app.reboot", uuidHex: uuids.reboot_uuid, size: 32, storageType: .int16)
        _ = registerConfig(name: "app.defaults", uuidHex: uuids.defaults_uuid, size: 32, storageType: .int16)
        _ = registerConfig(name: "app.maintainBLE", uuidHex: uuids.maintainBLE_uuid, size: 32, storageType: .int16)
        _ = registerConfig(name: "app.name", uuidHex: uuids.bleName_uuid, size: 32, storageType: .int16)
        
        _ = registerConfig(name: "motion.delay", uuidHex: uuids.motionDelay_uuid, size: 32, storageType: .int64)
        
        _ = registerConfig(name: "firmware.image", uuidHex: uuids.image_uuid, size: 32, storageType: .int16)
        _ = registerConfig(name: "firmware.verification", uuidHex: uuids.verify_uuid, size: 32, storageType: .int16)
        
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

    func writeStringCharacteristic(name: String, value: String, handler: @escaping () -> Void) -> Bool {
        if let thisCharacteristic = properties[name] {
            if let BLECharacteristic = selectedDevice?.findCharacteristic(uuid: thisCharacteristic.uuid) as? bleIntCharacteristic {
                let nsval = NSString(string: value)
                let data = Data(bytes: nsval.utf8String!, count: nsval.length)
                
                BLECharacteristic.writeHandler = handler
                selectedDevice?.peripheral?.writeValue(data, for: BLECharacteristic.characteristic, type: CBCharacteristicWriteType.withResponse)
                return true
            }
        }
        return false
    }
    
    func writeBytesCharacteristic(name: String, data: Data, handler: @escaping () -> Void) -> Bool {
        if let thisCharacteristic = properties[name] {
            if let BLECharacteristic = selectedDevice?.findCharacteristic(uuid: thisCharacteristic.uuid) as? bleIntCharacteristic {
                BLECharacteristic.writeHandler = handler
                selectedDevice?.peripheral?.writeValue(data, for: BLECharacteristic.characteristic, type: CBCharacteristicWriteType.withResponse)
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

    func writeInt16Characteristic(name: String, value: UInt16, handler: @escaping () -> Void) -> Bool {
        if let thisCharacteristic = properties[name] {
            if let BLECharacteristic = selectedDevice?.findCharacteristic(uuid: thisCharacteristic.uuid) as? bleIntCharacteristic {
                var nsval = NSInteger(value)
                let data = Data(bytes: &nsval, count: 1)

                BLECharacteristic.writeHandler = handler
                selectedDevice?.peripheral?.writeValue(data, for: BLECharacteristic.characteristic, type: CBCharacteristicWriteType.withResponse)
                return true
            }
        }
        return false
    }
    
    func reapExpiredAndScanAgain() {
        for recentPeripheral in peripherals {
            let howOld = recentPeripheral.lastSeen.timeIntervalSinceNow
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
            peripherals.append(ExpiringPeripheral(peripheral: peripheral, lastSeen: now))
            peripherals.sort {
                guard let left = $0.peripheral.name, let right = $1.peripheral.name else {
                    return false
                }
                return left < right
            }
            delegate?.deviceDiscovered(peripheral: peripheral)
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
        if advertisementData["kCBAdvDataLocalName"] != nil {
            print("name advertisements are: \(advertisementData)")
        }

        if let device = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? NSString {
            print("peripheral discovered: \(device)")

            if device.contains("mytracker-") == true {
                addOrUpdateDevice(peripheral: peripheral)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected to peripheral \(peripheral)")
        peripheral.discoverServices([uuids.convert(from: uuids.gsm_service), uuids.convert(from:uuids.mqtt_service), uuids.convert(from:uuids.version_service), uuids.convert(from:uuids.sim_service), uuids.convert(from:uuids.app_service), uuids.convert(from: uuids.firmware_service)])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("services discovered - errror? is \(error)")

        // device must have at least 1 service to discover or it will never be marked as discovered
        selectedDevice?.discovered = true
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
            serviceTree.discovered = true
            if (selectedDevice?.allServicesDiscovered())! {
                delegate?.discoveryComplete()
            }
        } else {
            print("**** danger will robinson: can't find service \(service.uuid)")
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnected from peripheral")
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        selectedDevice?.findCharacteristic(uuid: characteristic.uuid)?.writeHandler?()
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        selectedDevice?.findCharacteristic(uuid: characteristic.uuid)?.parse()
    }

    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        print("I see you have changed your name to \(peripheral.name)")

    }

}

protocol BLEConfigurationManagerDelegate : class {
    func deviceDiscovered(peripheral: CBPeripheral)
    func deviceDisappeared(peripheral: CBPeripheral)
    func discoveryComplete()
}
