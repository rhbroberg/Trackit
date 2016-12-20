//
//  RouteTableViewCell.swift
//  Trackit
//
//  Created by Richard Broberg on 12/4/16.
//  Copyright © 2016 Brobasino. All rights reserved.
//

import UIKit

class RouteTableViewCell: UITableViewCell {

    @IBOutlet weak var entries: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var created: UILabel!
    @IBOutlet weak var isVisible: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
