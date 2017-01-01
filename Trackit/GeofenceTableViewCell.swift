//
//  GeofenceTableViewCell.swift
//  Trackit
//
//  Created by Richard Broberg on 12/23/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//

import UIKit

class GeofenceTableViewCell: UITableViewCell {

    @IBOutlet weak var name: UILabel!
    
    var geofence: Geofence?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
