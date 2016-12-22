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

    weak var delegate: RouteTableViewCellDelegate?

    @IBAction func visibilityChanged(_ sender: Any) {
        delegate?.visibilityChange(isVisible: (isVisible?.isOn)!, whichCell: self)
    }

    var route: Route? {
        willSet {
            if let route = newValue {
                entries.text = "\(route.locations!.count)"
                name?.text = route.name!
                isVisible.isOn = route.isVisible
                let dateFormat = DateFormatter()
                dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
                dateFormat.timeZone = TimeZone.autoupdatingCurrent
                created?.text = dateFormat.string(for: route.startDate!)
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

protocol RouteTableViewCellDelegate: class {
    func visibilityChange(isVisible: Bool, whichCell: RouteTableViewCell)
}
