//
//  EventTableViewCell.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 3/26/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class EventTableViewCell: UITableViewCell {
    
    //MARK: Properties
    @IBOutlet weak var groupName: UILabel!
    @IBOutlet weak var admin: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
