//
//  GroupRequestTableViewCell.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/10/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class GroupRequestTableViewCell: UITableViewCell {

    // MARK: Properties
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var groupAdminLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
