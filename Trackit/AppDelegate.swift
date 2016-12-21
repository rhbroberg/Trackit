//
//  AppDelegate.swift
//  Trackit
//
//  Created by CS193p Instructor.
//  Copyright © 2016 Stanford University. All rights reserved.
//

import UIKit
import CoreData
import CocoaMQTT

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let userDefaults = UserDefaults.standard
    var window: UIWindow?
    var currentRoute: Route? {
        willSet {
            print("route being set")
            userDefaults.set(newValue?.name, forKey: "currentRoute")
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        print(NSHomeDirectory())
        let currentRouteName = userDefaults.string(forKey: "currentRoute") ?? "no route"

        let request: NSFetchRequest<Route> = Route.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", currentRouteName)
        
        do {
            let routes = try self.persistentContainer.viewContext.fetch(request)
            print("i see \(routes.count) matching routes to \(currentRouteName)")
            if routes.count == 1 {
                currentRoute = routes[0]
            }
        } catch {
            print("fetch failed, bummer")
        }

        enableMQTTListening()

        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("disconnecting mq")
        mqtt!.disconnect()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        print("reconnecting to mq")
        mqtt!.connect()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("terminating")
        mqtt!.disconnect()
    }

    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
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
        mqtt = CocoaMQTT(clientID: clientID, host: "ec2-54-175-5-136.compute-1.amazonaws.com", port: 1883)
        // mqtt!.secureMQTT = true
        if let mqtt = mqtt {
            mqtt.username = "rhb"
            mqtt.password = "dbe7ae0914d9f3c162b87304448fefa0"
            mqtt.willMessage = CocoaMQTTWill(topic: "/will", message: clientID + " shuffles off this mortal coil")
            mqtt.cleanSession = false
            mqtt.keepAlive = 60
            mqtt.delegate = self
        }
    }
    
    func enableMQTTListening() {
        if (reconnectTimer.isValid) {
            reconnectTimer.invalidate()
        }
        
        configureMQTTServer()
        mqtt!.connect()
    }
    
    func dataIsStable() {
        let coreDataContainer = persistentContainer.viewContext
        coreDataContainer.perform {
            do {
                print("saving data now")
                try coreDataContainer.save()
            }
            catch let error {
                print("Core data error: \(error)")
            }
        }
        let nc = NotificationCenter.default
        nc.post(name:dataIsStableNotification,
                object: nil,
                userInfo:[:])
    }
    
    var maxLocationId : Int?
    
    func addLocationToDb(message: CocoaMQTTMessage)
    {
        // latitude, longitude, altitude, course, speed, char, satellites, strength
        var messageParts = message.string!.characters.split { $0 == ";" }.map(String.init)
        
        let coreDataContainer = persistentContainer.viewContext
        coreDataContainer.perform {
            if self.maxLocationId == nil {
                self.maxLocationId = 0
                let request = NSFetchRequest<Location>(entityName: "Location")
                request.predicate = NSPredicate(format: "id==max(id)")

                
                if let results = try? coreDataContainer.fetch(request) {
                    for location in results as [NSManagedObject] {
                        let mymax = location.value(forKey: "id")! as! Int
                        print("db max id is \(mymax)")
                        self.maxLocationId = mymax
                    }
                }
            }
            
            if let location = NSEntityDescription.insertNewObject(forEntityName: "Location", into: coreDataContainer) as? Location
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
    }
    let incomingDataNotification = Notification.Name(rawValue: "incoming gps data")
    let dataIsStableNotification = Notification.Name(rawValue: "data is stable")
}

// MARK: mqtt Delegate

extension AppDelegate: CocoaMQTTDelegate {
    
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
        NotificationCenter.default.post(name:incomingDataNotification, object: nil, userInfo:["message":message.string!, "topic": message.topic])
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
                                                   selector: #selector(AppDelegate.dataIsStable),
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
                                                  selector: #selector(AppDelegate.enableMQTTListening),
                                                  userInfo: nil, repeats: true)
            break
        }

    }
    
    func _console(_ info: String) {
        print("Delegate: \(info)")
    }
}

