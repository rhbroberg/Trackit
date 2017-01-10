//
//  BLEConfigurationManager.swift
//  Trackit
//
//  Created by Richard Broberg on 1/8/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import UIKit
import CoreBluetooth

class UUIDBase {
    
}

class BLECharacteristic : UUIDBase {
    let characteristic : CBCharacteristic
    
    init(characteristic : CBCharacteristic)
    {
        self.characteristic = characteristic
        super.init()
    }

    func parse() {
    }
}

class bleIntCharacteristic : BLECharacteristic {
    var readHandler: ((_ value : UInt16) -> Void)?

    override func parse() {
        if let data = characteristic.value {
            var bytes = Array(repeating: 0 as UInt8, count:data.count) //MemoryLayout.size(ofValue: count)/MemoryLayout<UInt8>.size)

            var myint : UInt16 = 0
            if data.count > 1 {
                data.copyBytes(to: &bytes, count:data.count)
                let data16 = bytes.map { UInt16($0) }
                myint = 256 * data16[1] + data16[0]
                readHandler?(myint)
            }
        }
    }
}

class bleStringCharacteristic: BLECharacteristic {
    var readHandler: ((_ value : String) -> Void)?

    override func parse() {
        if let data = characteristic.value {
            let s = String(bytes: data, encoding: String.Encoding.utf8)
            readHandler?(s!)
        }
    }
}

class BLEService : UUIDBase {
    let service : CBService
    var characteristics : [CBUUID : BLECharacteristic] = [:]
    
    init(service: CBService) {
        self.service = service
        super.init()
    }

    // turn me into a template on type of ble.*Characteristic
    func registerCharacteristic(characteristic : CBCharacteristic, storageType: bleConfiguration.StorageImplementation) {
        switch storageType {
        case .string:
            characteristics[characteristic.uuid] = bleStringCharacteristic(characteristic: characteristic)
        case .int16:
            characteristics[characteristic.uuid] = bleIntCharacteristic(characteristic: characteristic)
        default:
            print("*** not registering uuid \(characteristic.uuid) - no support yet")
            break
        }
    }

    func findCharacteristic(which: CBCharacteristic) -> BLECharacteristic? {
        return characteristics[which.uuid]
    }
}

class BLEDevice : UUIDBase {
    var peripheral: CBPeripheral?
    var services : [CBUUID : BLEService] = [:]
    
    func registerService(service: CBService) {
        let newService = BLEService(service: service)
        services[service.uuid] = newService
    }
    
    func findService(service: CBService) ->BLEService? {
        return services[service.uuid]
    }
    
    func findCharacteristic(uuid: CBUUID) -> BLECharacteristic? {
        for service in services {
            for characteristic in service.value.characteristics {
                if characteristic.key == uuid {
                    return characteristic.value
                }
            }
        }
        return nil
    }

    init(peripheral: CBPeripheral?, delegate: CBPeripheralDelegate) {
        self.peripheral = peripheral
        peripheral!.delegate = delegate
        super.init()
    }
}

struct bleConfiguration {
    let uuid : CBUUID
    let size : Int
    let storageType : StorageImplementation
    var value : String?

    enum StorageImplementation {
        case int8
        case int16
        case int32
        case int64
        case string
    }
}

class BLEConfigurationManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var foundDevice : BLEDevice?
    var byUUID : [CBUUID : String]
    var properties : [String : bleConfiguration]

    var cbManager: CBCentralManager?
    var delegate : BLEConfigurationManagerDelegate?

    func registerConfig(name: String, uuidHex: [UInt8], size: Int, storageType: bleConfiguration.StorageImplementation) -> bleConfiguration {
        let uuid = uuids.convert(from: uuidHex)
        properties[name] = bleConfiguration(uuid: uuid, size: size, storageType: storageType, value: nil)
        byUUID[uuid] = name

        return properties[name]!
    }

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

    func readStringCharacteristic(name : String, handler: @escaping (_ value: String) -> Void) -> Bool {
        if let thisCharacteristic = properties[name] {
            if let BLECharacteristic = foundDevice?.findCharacteristic(uuid: thisCharacteristic.uuid) as? bleStringCharacteristic {
                BLECharacteristic.readHandler = handler
                foundDevice?.peripheral?.readValue(for: BLECharacteristic.characteristic)
                return true
            }
        }
        return false
    }

    func readInt16Characteristic(name : String, handler: @escaping (_ value: UInt16) -> Void) -> Bool {
        if let thisCharacteristic = properties[name] {
            if let BLECharacteristic = foundDevice?.findCharacteristic(uuid: thisCharacteristic.uuid) as? bleIntCharacteristic {
                BLECharacteristic.readHandler = handler
                foundDevice?.peripheral?.readValue(for: BLECharacteristic.characteristic)
                return true
            }
        }
        return false
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
            cbManager?.stopScan()
            self.foundDevice = BLEDevice(peripheral: peripheral, delegate: self)
            
            cbManager?.connect(peripheral, options: nil)
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
            
            foundDevice?.registerService(service: thisService)
//            print("discovering characteristics now for \(thisService)")
            peripheral.discoverCharacteristics(nil, for: thisService)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let serviceTree = foundDevice?.findService(service: service) {
            for characteristic in service.characteristics! {
                let thisCharacteristic = characteristic as CBCharacteristic
                
                if let which = byUUID[thisCharacteristic.uuid] {
                    serviceTree.registerCharacteristic(characteristic: thisCharacteristic, storageType: (properties[which]!.storageType))
                }
                
                self.foundDevice?.peripheral?.setNotifyValue(true, for: thisCharacteristic)
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
        
        foundDevice?.findCharacteristic(uuid: characteristic.uuid)?.parse()
    }
}

protocol BLEConfigurationManagerDelegate : class {
    func deviceFound()
}
