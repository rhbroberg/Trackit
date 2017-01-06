//
//  DeviceTableViewCell.swift
//  Trackit
//
//  Created by Richard Broberg on 1/4/17.
//  Copyright © 2017 Brobasino. All rights reserved.
//

import UIKit

class DeviceTableViewCell: UITableViewCell {

    @IBOutlet weak var name: UILabel!

    var device : Device?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
