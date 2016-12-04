//
//  GPXViewController.swift
//  Trackit
//
//  Created by CS193p Instructor.
//  Copyright © 2016 Stanford University. All rights reserved.
//

import UIKit
import MapKit
import CocoaMQTT
import CoreData

class GPXViewController: UIViewController, MKMapViewDelegate, UIPopoverPresentationControllerDelegate
{
    // MARK: Public Model

    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    var gpxURL: URL? {
        didSet {
            clearWaypoints()
            if let url = gpxURL {
                GPX.parse(url) { gpx in
                    if gpx != nil {
                        self.addWaypoints(gpx!.waypoints)
                    }
                }
            }
        }
    }

    var mqtt: CocoaMQTT?
    
    func configureMQTTServer() {
        let clientID = "ios-app-" + UIDevice.current.identifierForVendor!.uuidString
        mqtt = CocoaMQTT(clientID: clientID, host: "ec2-54-175-5-136.compute-1.amazonaws.com", port: 1883)
        //        mqtt!.secureMQTT = true
        if let mqtt = mqtt {
            mqtt.username = "rhb"
            mqtt.password = "dbe7ae0914d9f3c162b87304448fefa0"
            mqtt.willMessage = CocoaMQTTWill(topic: "/will", message: clientID + " shuffles off this mortal coil")
            mqtt.cleanSession = false
            mqtt.keepAlive = 60
            mqtt.delegate = self
        }
    }

    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerReveal(menuButton: menuButton)
        initializeVisibleRoutes(routes: ["frist"])
        connect()
    }

    func connect() {
        if (reconnectTimer.isValid) {
            reconnectTimer.invalidate()
        }

        configureMQTTServer()
        mqtt!.connect()
    }

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.mapType = .standard // .satellite
            mapView.delegate = self
        }
    }
    
    func initializeVisibleRoutes(routes: [String]) {
        for route in routes {
            coreDataContainer?.perform {
                print("loading route \(route)")
                let request = NSFetchRequest<Location>(entityName: "Location")
                let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
                request.sortDescriptors = [sortDescriptor]
                //            request.predicate = NSPredicate(format: "route = %@", route);
                
                if let results = try? self.coreDataContainer!.fetch(request) {
                    print("i see \(results.count) locations")
                    for location in results as [NSManagedObject] {
                        let latitude: Float = location.value(forKey: "latitude")! as! Float
                        let longitude: Float = location.value(forKey: "longitude")! as! Float
                        self.addToRoute(latitude: String(format: "%.9f", latitude), longitude: String(format: "%.9f",longitude))
                    }
                }
                DispatchQueue.main.async {
                    self.registerOverlay(isInitial: false)
                }
            }
        }
    }
    
    // MARK: Private Implementation

    fileprivate func clearWaypoints() {
        mapView?.removeAnnotations(mapView.annotations)
    }
    
    fileprivate func addWaypoints(_ waypoints: [GPX.Waypoint]) {
        mapView?.addAnnotations(waypoints)
        mapView?.showAnnotations(waypoints, animated: true)
    }
    
    fileprivate func selectWaypoint(_ waypoint: GPX.Waypoint?) {
        if waypoint != nil {
            mapView.selectAnnotation(waypoint!, animated: true)
        }
    }
    
    // MARK: MKMapViewDelegate

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view: MKAnnotationView! = mapView.dequeueReusableAnnotationView(withIdentifier: Constants.AnnotationViewReuseIdentifier)
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.AnnotationViewReuseIdentifier)
            view.canShowCallout = true
        } else {
            view.annotation = annotation
        }
        
        view.isDraggable = annotation is EditableWaypoint
    
        view.leftCalloutAccessoryView = nil
        view.rightCalloutAccessoryView = nil
        if let waypoint = annotation as? GPX.Waypoint {
            if waypoint.thumbnailURL != nil {
                view.leftCalloutAccessoryView = UIButton(frame: Constants.LeftCalloutFrame)
            }
            if waypoint is EditableWaypoint {
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
        }
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let thumbnailImageButton = view.leftCalloutAccessoryView as? UIButton,
            let url = (view.annotation as? GPX.Waypoint)?.thumbnailURL,
            let imageData = try? Data(contentsOf: url as URL), // blocks main queue
            let image = UIImage(data: imageData) {
            thumbnailImageButton.setImage(image, for: UIControlState())
        }
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.leftCalloutAccessoryView {
            performSegue(withIdentifier: Constants.ShowImageSegue, sender: view)
        } else if control == view.rightCalloutAccessoryView  {
            mapView.deselectAnnotation(view.annotation, animated: true)
            performSegue(withIdentifier: Constants.EditUserWaypoint, sender: view)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            print("rendering for overlay")
            let lineView = MKPolylineRenderer(overlay: overlay)
            lineView.strokeColor = UIColor.red
            lineView.lineWidth = 1.0

            return lineView
        }
        return MKPolylineRenderer()
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination.contentViewController
        let annotationView = sender as? MKAnnotationView
        let waypoint = annotationView?.annotation as? GPX.Waypoint
        
        if segue.identifier == Constants.ShowImageSegue {
            if let ivc = destination as? ImageViewController {
                ivc.imageURL = waypoint?.imageURL
                ivc.title = waypoint?.name
            }
        } else if segue.identifier == Constants.EditUserWaypoint {
            if let editableWaypoint = waypoint as? EditableWaypoint,
                let ewvc = destination as? EditWaypointViewController {
                if let ppc = ewvc.popoverPresentationController {
                    ppc.sourceRect = annotationView!.frame
                    ppc.delegate = self
                }
                ewvc.waypointToEdit = editableWaypoint
            }
        }
    }

    func addWaypoint(coordinate: CLLocationCoordinate2D, name: String)
    {
            let waypoint = EditableWaypoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
            waypoint.name = name
            mapView.addAnnotation(waypoint)
    }
    
    // Long press gesture adds a waypoint

    @IBAction func addWaypoint(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let coordinate = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
            addWaypoint(coordinate: coordinate, name: "Dropped")
        }
    }
    
    // Unwind target (selects just-edited waypoint)

    @IBAction func updatedUserWaypoint(_ segue: UIStoryboardSegue) {
        selectWaypoint((segue.source.contentViewController as? EditWaypointViewController)?.waypointToEdit)
    }
    
    // MARK: UIPopoverPresentationControllerDelegate
    
    // when popover is dismissed, selected the just-edited waypoint
    // see also unwind target above (does the same thing for adapted UI)

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        selectWaypoint((popoverPresentationController.presentedViewController as? EditWaypointViewController)?.waypointToEdit)
    }
    
    // if we're horizontally compact
    // then adapt by going to .OverFullScreen
    // .OverFullScreen fills the whole screen, but lets underlying MVC show through

    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        return traitCollection.horizontalSizeClass == .compact ? .overFullScreen : .none
    }
    
    // when adapting to full screen
    // wrap the MVC in a navigation controller
    // and install a blurring visual effect behind all the navigation controller draws
    // autoresizingMask is "old style" constraints
    
    func presentationController(
        _ controller: UIPresentationController,
        viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle
        ) -> UIViewController? {
        if style == .fullScreen || style == .overFullScreen {
            let navcon = UINavigationController(rootViewController: controller.presentedViewController)
            let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
            visualEffectView.frame = navcon.view.bounds
            visualEffectView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
            navcon.view.insertSubview(visualEffectView, at: 0)
            return navcon
        } else {
            return nil
        }
    }
    
    // MARK: Constants
    
    fileprivate struct Constants {
        static let LeftCalloutFrame = CGRect(x: 0, y: 0, width: 59, height: 59) // sad face
        static let AnnotationViewReuseIdentifier = "waypoint"
        static let ShowImageSegue = "Show Image"
        static let EditUserWaypoint = "Edit Waypoint"
    }

    var pointsToUse: [CLLocationCoordinate2D] = []
    var addOverlayTimer = Timer()
    var reconnectTimer = Timer()
    var lastReceived = Date()
    var myPolyline = MKPolyline()

    func dataIsStable() {
        registerOverlay(isInitial: true)
        coreDataContainer?.perform {
            do {
                print("saving data now")
                try self.coreDataContainer?.save()
            }
            catch let error {
                print("Core data error: \(error)")
            }
        }
    }
    
    func registerOverlay(isInitial: Bool) {
        // delete old one first
        if (myPolyline.pointCount > 0) {
            mapView.remove(myPolyline)
        }

        myPolyline = MKPolyline(coordinates: &pointsToUse, count: pointsToUse.count)
        print("adding polyline to view for \(pointsToUse.count) points")
        mapView.add(myPolyline)

        // http://stackoverflow.com/questions/13569327/zoom-mkmapview-to-fit-polyline-points
        if let first = mapView.overlays.first {
            let rect = mapView.overlays.reduce(first.boundingMapRect, {MKMapRectUnion($0, $1.boundingMapRect)})
            mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 50.0, left: 50.0, bottom: 50.0, right: 50.0), animated: isInitial)
        }
    }

    func addToRoute(latitude : String, longitude : String) {
        let p = CGPointFromString("{\(latitude),\(longitude)}")
        if (pointsToUse.count == 0) {
            addWaypoint(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(p.x), longitude: CLLocationDegrees(p.y)), name: "Starting Point")
        }
        pointsToUse += [CLLocationCoordinate2DMake(CLLocationDegrees(p.x), CLLocationDegrees(p.y))]
     }

    var coreDataContainer : NSManagedObjectContext? =
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
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
}

// MARK:

extension GPXViewController: CocoaMQTTDelegate {
    
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
        var gpsArray = message.string!.characters.split { $0 == ";" }.map(String.init)
        addToRoute(latitude: gpsArray[0], longitude: gpsArray[1])
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
                                                   selector: #selector(GPXViewController.dataIsStable),
                                                   userInfo: nil, repeats: false)
        }
        lastReceived = Date()
        
        let name = Notification.Name(rawValue: "MQTTMessageNotification")
        NotificationCenter.default.post(name: name, object: self, userInfo: ["message": message.string!, "topic": message.topic])
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
        _console("mqttDidDisconnect " + err.debugDescription)
        reconnectTimer = Timer.scheduledTimer(timeInterval: 5.0, target:self,
                                              selector: #selector(GPXViewController.connect),
                                              userInfo: nil, repeats: true)
    }
    
    func _console(_ info: String) {
        print("Delegate: \(info)")
    }
}

extension UIViewController {
    var contentViewController: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController ?? navcon
        } else {
            return self
        }
    }
    
    func registerReveal(menuButton: UIBarButtonItem) {
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            self.revealViewController().rearViewRevealWidth = 130
        }
    }
}

