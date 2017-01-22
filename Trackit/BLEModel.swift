//
//  BLEModel.swift
//  Trackit
//
//  Created by Richard Broberg on 1/18/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import Foundation
import CoreBluetooth

class UUIDBase {
    
}

class BLECharacteristic : UUIDBase {
    let characteristic : CBCharacteristic
    var discovered : Bool
    var writeHandler: (() -> Void)?

    init(characteristic : CBCharacteristic)
    {
        self.characteristic = characteristic
        self.discovered = false
        super.init()
    }

    func parse() {
    }
}

class bleIntCharacteristic : BLECharacteristic {
    var readHandler: ((_ value : UInt16) -> Void)?

    override func parse() {
        discovered = true
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
        discovered = true
        if let data = characteristic.value {
            let s = String(bytes: data, encoding: String.Encoding.utf8)
            readHandler?(s!)
        }
    }
}

class BLEService : UUIDBase {
    let service : CBService
    var characteristics : [CBUUID : BLECharacteristic] = [:]
    var discovered : Bool
    weak var peripheral : CBPeripheral?

    init(service: CBService, peripheral: CBPeripheral) {
        self.service = service
        self.discovered = false
        self.peripheral = peripheral
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
    
    func allCharacteristicsDiscovered() -> Bool {
        for characteristic in characteristics {
            if !characteristic.value.discovered {
                return false
            }
        }
        return true
    }
}

class BLEDevice : UUIDBase {
    var peripheral: CBPeripheral?
    var services : [CBUUID : BLEService] = [:]
    var discovered : Bool

    func registerService(service: CBService) {
        let newService = BLEService(service: service, peripheral: peripheral!)
        discovered = true
        services[service.uuid] = newService
    }

    func findService(service: CBService) ->BLEService? {
        return services[service.uuid]
    }

    func findCharacteristic(uuid: CBUUID) -> BLECharacteristic? {
        for service in services {
            if let characteristic = service.value.characteristics[uuid] {
                return characteristic
            }
        }
        return nil
    }

    init(peripheral: CBPeripheral?, delegate: CBPeripheralDelegate) {
        self.peripheral = peripheral
        self.discovered = false
        peripheral!.delegate = delegate
        super.init()
    }

    func allServicesDiscovered() -> Bool {
        for service in services {
            if !service.value.discovered {
                return false
            }
        }
        return discovered && true
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
