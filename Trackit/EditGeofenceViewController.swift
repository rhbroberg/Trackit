//
//  EditGeofenceViewController.swift
//  Trackit
//
//  Created by Richard Broberg on 12/23/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class EditGeofenceViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var radius: UISlider!
    @IBOutlet weak var notify: UISwitch!
    @IBOutlet weak var category: UISegmentedControl!
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.mapType = .standard
            mapView.delegate = self
        }
    }
    @IBAction func radiusChanged(_ sender: Any) {
        registerFencingCircle()
    }
    @IBOutlet weak var radiusText: UILabel!
    @IBAction func categoryChanged(_ sender: Any) {
        switch category!.selectedSegmentIndex {
        case 1:
            break
        default:
            removeCenter()
        }
        switch category!.selectedSegmentIndex {
        case 2:
            removeFencingCircle()
        default:
            break
        }
    }

    // long press gesture for center point
    @IBAction func defineCenter(_ sender: UILongPressGestureRecognizer) {
        switch category!.selectedSegmentIndex {
        case 1:
            if sender.state == .began {
                let coordinate = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
                addCenter(coordinate: coordinate, name: "Center")
            }
        default: break
        }
    }

    var staticCenter: EditableWaypoint?

    func addCenter(coordinate: CLLocationCoordinate2D, name: String)
    {
        removeCenter()
        staticCenter = EditableWaypoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
        staticCenter!.name = name
        mapView.addAnnotation(staticCenter!)
        registerFencingCircle()
    }

    func removeCenter() {
        if let existingCenter = staticCenter {
            mapView.removeAnnotation(existingCenter)
        }
    }
    
    // MARK: - MKMapViewDelegate
    var lastUserLocation:  MKUserLocation?

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if category!.selectedSegmentIndex == 0 {
            mapView.centerCoordinate = userLocation.location!.coordinate

            let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
            self.mapView.setRegion(region, animated: false)
            lastUserLocation = userLocation
            registerFencingCircle()
        }
    }

    var fencingCircle = MKCircle()

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let lineView = MKCircleRenderer(overlay: overlay)
            lineView.strokeColor = UIColor.green
            lineView.lineWidth = 1.0
            lineView.fillColor = .orange
            lineView.alpha = 0.1

            return lineView
        }
        return MKCircleRenderer()
    }

    func registerFencingCircle() {
        var center : CLLocationCoordinate2D?

        switch category!.selectedSegmentIndex {
        case 0:
        // only draw circle if current location has been acquired
        if let lastUserLocation = lastUserLocation {
            center = CLLocationCoordinate2D(latitude: lastUserLocation.coordinate.latitude, longitude: lastUserLocation.coordinate.longitude)
        }
        case 1:
            if let staticCenter = staticCenter {
                center = CLLocationCoordinate2D(latitude: staticCenter.coordinate.latitude, longitude: staticCenter.coordinate.longitude)
            }
        default: break
        }

        removeFencingCircle()
        if let center = center {
            fencingCircle = MKCircle(center: center, radius: CLLocationDistance(radius.value))
            mapView.add(fencingCircle)
            radiusText!.text = "\(radius.value)"
        }
    }

    func removeFencingCircle() {
        mapView.remove(fencingCircle)
    }
    
    // start out with no geofence defined upon creation; if the type is changed
    // replace instance with new type.  return type when view disappears
    var geofence: Geofence?
    weak var delegate: EditGeofenceViewControllerDelegate?
    var coreDataContainer : NSManagedObjectContext? =
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    func handleTap(gestureRecognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let locationManager = CLLocationManager()
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true

        // allow any tap in view to dismiss keyboard
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(EditGeofenceViewController.handleTap))
        self.view.addGestureRecognizer(gestureRecognizer)

        if geofence == nil {
            name!.text = "boundary"
        }
        else {
            name!.text = geofence?.name
            notify!.isOn = (geofence?.shouldNotify)!

            if let dynamicFence = geofence as? DynamicGeofence {
                category!.selectedSegmentIndex = 0
                radius!.value = dynamicFence.radius
            }
            if let staticFence = geofence as? StaticRadiusGeofence {
                category!.selectedSegmentIndex = 1
                radius!.value = staticFence.radius
                let center = CLLocationCoordinate2DMake(staticFence.latitude, staticFence.longitude)
                addCenter(coordinate: center, name: "Center")

                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
                self.mapView.setRegion(region, animated: false)
            }
        }

        // Do any additional setup after loading the view.
    }

    func createGeofence() {
        print("creating default geofence")
        coreDataContainer?.performAndWait {
            switch self.category!.selectedSegmentIndex {
            case 0:
                if let geofence = NSEntityDescription.insertNewObject(forEntityName: "DynamicGeofence", into: self.coreDataContainer!) as? DynamicGeofence {
                    geofence.name = self.name!.text
                    geofence.radius = self.radius!.value
                    geofence.shouldNotify = self.notify!.isOn
                    self.geofence = geofence
                }
            case 1:
                if let geofence = NSEntityDescription.insertNewObject(forEntityName: "StaticRadiusGeofence", into: self.coreDataContainer!) as? StaticRadiusGeofence {
                    geofence.name = self.name!.text
                    geofence.latitude = (self.staticCenter?.coordinate.latitude)!
                    geofence.longitude = (self.staticCenter?.coordinate.longitude)!
                    geofence.radius = self.radius!.value
                    geofence.shouldNotify = self.notify!.isOn
                    self.geofence = geofence
                }
            default: break
            }

            (UIApplication.shared.delegate as! AppDelegate).saveContext(context: self.coreDataContainer)
        }
    }

    func updateGeofence() {
        geofence!.name = self.name!.text
        geofence!.shouldNotify = self.notify!.isOn
        
        switch self.category!.selectedSegmentIndex {
        case 0:
            if let geofence = geofence as? DynamicGeofence {
                geofence.radius = self.radius!.value
            }
        case 1:
            if let geofence = geofence as? StaticRadiusGeofence {
                geofence.latitude = (self.staticCenter?.coordinate.latitude)!
                geofence.longitude = (self.staticCenter?.coordinate.longitude)!
                geofence.radius = self.radius!.value
            }
        default: break
        }
        (UIApplication.shared.delegate as! AppDelegate).saveContext(context: coreDataContainer)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // it's probably time to move these behaviors into the subclasses rather than all the switch-case-ing
        // first case: geofence added from scratch
        if geofence == nil {
            createGeofence()
        }
        else {
            updateGeofence()
        }

        // propagate changed object to delegate
        delegate?.specificGeofenceChanged(newFence: geofence!)

        let locationManager = CLLocationManager()
        locationManager.stopUpdatingLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

protocol EditGeofenceViewControllerDelegate: class {
    func specificGeofenceChanged(newFence: Geofence)
}
