//
//  RouteNameViewController.swift
//  Trackit
//
//  Created by Richard Broberg on 12/20/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//

import UIKit
import CoreData

class RouteNameViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var value: UITextField!
    
    var route: Route?
    var coreDataContainer : NSManagedObjectContext? =
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()

        value.becomeFirstResponder()
        value.text = route?.name
        // Do any additional setup after loading the view.
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if value.text != route?.name {
            print("sneaky bastage - changed the name!")
            coreDataContainer?.performAndWait {
                self.route?.name = self.value.text

                do {
                    print("saving data now")
                    try self.coreDataContainer?.save()
                }
                catch let error {
                    print("Core data error: \(error)")
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
