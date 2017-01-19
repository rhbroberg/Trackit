//
//  SearchDeviceTableViewCell.swift
//  Trackit
//
//  Created by Richard Broberg on 1/13/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import UIKit
import CoreBluetooth

class SearchDeviceTableViewCell: UITableViewCell {

    @IBOutlet weak var name: UILabel!
    var peripheral : CBPeripheral? {
        willSet {
            if newValue != nil {
                name!.text = newValue?.name
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
