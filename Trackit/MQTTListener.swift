//
//  MQTTListener.swift
//  Trackit
//
//  Created by Richard Broberg on 12/29/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//

import UIKit
import CoreData
import CocoaMQTT
import CoreLocation

class MQTTListener: NSObject {
    lazy var coreDataContainer : NSManagedObjectContext? =
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let userDefaults = UserDefaults.standard

    func saveContext () {
        let context = coreDataContainer
        if (context?.hasChanges)! {
            do {
                try context?.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - async networking
    
    var mqtt: CocoaMQTT?
    var addOverlayTimer = Timer()
    var reconnectTimer = Timer()
    var lastReceived = Date()
    
    func configureMQTTServer() {
        let clientID = "ios-app-" + UIDevice.current.identifierForVendor!.uuidString
        mqtt = CocoaMQTT(clientID: clientID, host: userDefaults.string(forKey: "settings.connection.server") ?? "ec2-54-175-5-136.compute-1.amazonaws.com", port: UInt16(userDefaults.integer(forKey: "settings.connection.port")))
        mqtt!.secureMQTT = userDefaults.bool(forKey: "settings.connection.isSecure")
        if let mqtt = mqtt {
            let userDefaults = UserDefaults.standard
            
            mqtt.username = userDefaults.string(forKey: "settings.account.username") ?? "rhb"
            mqtt.password = userDefaults.string(forKey: "settings.account.password") ?? "dbe7ae0914d9f3c162b87304448fefa0"
            mqtt.willMessage = CocoaMQTTWill(topic: "/will", message: clientID + " shuffles off this mortal coil")
            mqtt.cleanSession = false
            mqtt.keepAlive = UInt16(userDefaults.integer(forKey: "settings.connection.keepAlive"))
            mqtt.delegate = self
        }
    }
    
    func enable() {
        if (reconnectTimer.isValid) {
            reconnectTimer.invalidate()
        }
        
        configureMQTTServer()
        mqtt!.connect()
    }
    
    func disconnect() {
        mqtt?.disconnect()
    }
    
    func connect() {
        mqtt?.connect()
    }

    func dataIsStable() {
        coreDataContainer?.perform {
            do {
                print("saving data now")
                try self.coreDataContainer?.save()
            }
            catch let error {
                print("Core data error: \(error)")
            }
        }
        let nc = NotificationCenter.default
        nc.post(name: (UIApplication.shared.delegate as! AppDelegate).dataIsStableNotification,
                object: nil,
                userInfo:[:])
    }
    
    var maxLocationId : Int?
    
    func addLocationToDb(message: CocoaMQTTMessage)
    {
        // latitude, longitude, altitude, course, speed, char, satellites, strength
        var messageParts = message.string!.characters.split { $0 == ";" }.map(String.init)
        
        coreDataContainer?.perform {
            if self.maxLocationId == nil {
                self.maxLocationId = 0
                let request = NSFetchRequest<Location>(entityName: "Location")
                request.predicate = NSPredicate(format: "id==max(id)")
                
                
                if let results = try? self.coreDataContainer!.fetch(request) {
                    for location in results as [NSManagedObject] {
                        let mymax = location.value(forKey: "id")! as! Int
                        print("db max id is \(mymax)")
                        self.maxLocationId = mymax
                    }
                }
            }
            
            if let location = NSEntityDescription.insertNewObject(forEntityName: "Location", into: self.coreDataContainer!) as? Location
            {
                location.route = (UIApplication.shared.delegate as! AppDelegate).currentRoute
                location.latitude = Float(messageParts[0])!
                location.longitude = Float(messageParts[1])!
                location.altitude = Float(messageParts[2])!
                location.course = Float(messageParts[3])!
                location.speed = Float(messageParts[4])!
                location.satellites = Int64(messageParts[6])!
                location.signal = Int64(messageParts[7])!
                location.timestamp = NSDate.init()  // fake it until datastream has timestamp in it
                location.id = Int64(self.maxLocationId!)
                self.maxLocationId! += 1
            }
        }
        testBounds(latitude: Float(messageParts[0])!, longitude: Float(messageParts[1])!)
    }
    
    func testBounds(latitude: Float, longitude: Float) {
        //        let center = CLLocationCoordinate2D(latitude: lastUserLocation.coordinate.latitude, longitude: lastUserLocation.coordinate.longitude)
        //        fencingCircle = MKCircle(center: center, radius: CLLocationDistance(radius.value))
        // foreach geofence, test with this point
        // provide method at superclass, invoke on each concrete subclass.  dynamic one needs most recent phone location
    }
}


// MARK: mqtt Delegate

extension MQTTListener: CocoaMQTTDelegate {
    
    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("didConnect \(host):\(port)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("didConnectAck: \(ack)，rawValue: \(ack.rawValue), accept = \(ack) ")
        
        if ack == .accept {
            mqtt.subscribe("rhb/f/+", qos: CocoaMQTTQOS.qos1)
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didPublishMessage with message: \(message.string)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublishAck with id: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        NotificationCenter.default.post(name: (UIApplication.shared.delegate as! AppDelegate).incomingDataNotification, object: nil, userInfo:["message":message.string!, "topic": message.topic])
        addLocationToDb(message: message)

        if (addOverlayTimer.isValid) {
            addOverlayTimer.invalidate()
        }
        
        if (lastReceived.timeIntervalSinceNow < -1) {
            print("rendering immediately")
            dataIsStable()
        }
        else {
            print("datastream coming in too fast; delaying render")
            addOverlayTimer = Timer.scheduledTimer(timeInterval: 1.0, target:self,
                                                   selector: #selector(MQTTListener.dataIsStable),
                                                   userInfo: nil, repeats: false)
        }
        lastReceived = Date()
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("didSubscribeTopic to \(topic)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("didUnsubscribeTopic to \(topic)")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("didPing")
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        _console("didReceivePong")
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        switch UIApplication.shared.applicationState {
        case .background:
            print("app in Background, not reconnecting")
        default:
            print("reconnecting")
            
            _console("mqttDidDisconnect " + err.debugDescription)
            reconnectTimer = Timer.scheduledTimer(timeInterval: 5.0, target:self,
                                                  selector: #selector(MQTTListener.enable),
                                                  userInfo: nil, repeats: true)
            break
        }
        
    }
    
    func _console(_ info: String) {
        print("Delegate: \(info)")
    }
}
