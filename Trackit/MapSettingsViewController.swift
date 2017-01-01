//
//  MapSettingsTableViewController.swift
//  Trackit
//
//  Created by Richard Broberg on 1/1/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import UIKit
import MapKit

class MapSettingsViewController: UIViewController {

    @IBOutlet weak var viewType: UISegmentedControl!
    @IBOutlet weak var regionRule: UISegmentedControl!
    @IBOutlet weak var boundingStack: UIStackView!

    var mapView : MKMapView?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let mapView = mapView {
            var viewTypeSegment = 0
            switch mapView.mapType {
            case .standard:
                viewTypeSegment = 0
            case .satellite:
                viewTypeSegment = 1
            case .hybrid:
                viewTypeSegment = 2
            default: break
            }
            viewType?.selectedSegmentIndex = viewTypeSegment
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let mapView = mapView {
            var mapType : MKMapType = .standard

            switch viewType!.selectedSegmentIndex {
            case 0:
                mapType = .standard
            case 1:
                mapType = .satellite
            case 2:
                mapType = .hybrid
            default: break
            }
            mapView.mapType = mapType
        }
    }

//        boundingStack?.translatesAutoresizingMaskIntoConstraints = false

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // there is a (x,y) offset of the boundingStack view within its parent (this class); make the window size have
        // the same margin to the right as left; and the same margin to the bottom as top
        let offset = boundingStack.convert(boundingStack.bounds.origin, to: self.view)
        preferredContentSize = CGSize(width: boundingStack.bounds.size.width + offset.x * 2, height: boundingStack.bounds.size.height + offset.y * 2)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
