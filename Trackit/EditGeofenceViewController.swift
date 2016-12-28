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

    // MARK: - MKMapViewDelegate
    var lastUserLocation:  MKUserLocation?

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        mapView.centerCoordinate = userLocation.location!.coordinate

        let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
        self.mapView.setRegion(region, animated: true)
        lastUserLocation = userLocation
        registerFencingCircle()
    }

    var fencingCircle = MKCircle()

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let lineView = MKCircleRenderer(overlay: overlay)
            lineView.strokeColor = UIColor.green
            lineView.lineWidth = 1.0

            return lineView
        }
        return MKCircleRenderer()
    }

    func registerFencingCircle() {
        // only draw circle if current location has been acquired
        if let lastUserLocation = lastUserLocation {
            mapView.remove(fencingCircle)
            let center = CLLocationCoordinate2D(latitude: lastUserLocation.coordinate.latitude, longitude: lastUserLocation.coordinate.longitude)
            fencingCircle = MKCircle(center: center, radius: CLLocationDistance(radius.value))
            mapView.add(fencingCircle)
            radiusText!.text = "\(radius.value)"
        }
    }

    // start out with no geofence defined upon creation; if the type is changed
    // replace instance with new type.  return type when view disappears
    var geofence: Geofence?
    weak var delegate: EditGeofenceViewControllerDelegate?
    var coreDataContainer : NSManagedObjectContext? =
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let locationManager = CLLocationManager()
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true

        if geofence == nil {
            name!.text = "boundary"
        }
        else {
            name!.text = geofence?.name
            notify!.isOn = (geofence?.shouldNotify)!

            if let dynamicFence = geofence as? DynamicGeofence {
                radius!.value = dynamicFence.radius
            }
        }
        
        // Do any additional setup after loading the view.
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // not sure this is the right path; would have to create a subclass of geofence in the managed context
        // and delete it each time the user selects a different type.   maybe this class needs to
        // have other objects to hold onto the subclass state - like a polygon, and the (latitude, longtitude) center;
        // that way, the creation of the object can be deferred until the last possible minute.
        // deletion of the previous object will have to occur if it was non-nill

        // first case: geofence added from scratch
        if geofence == nil {
            print("creating default geofence")
            coreDataContainer?.performAndWait {
                if let geofence = NSEntityDescription.insertNewObject(forEntityName: "DynamicGeofence", into: self.coreDataContainer!) as? DynamicGeofence {
                    geofence.name = self.name!.text
                    geofence.radius = self.radius!.value
                    geofence.shouldNotify = self.notify!.isOn
                    self.geofence = geofence
                }

                do {
                    try self.coreDataContainer?.save()
                }
                catch {
                    print("Core data error: \(error)")
                }
            }
            
        }
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
