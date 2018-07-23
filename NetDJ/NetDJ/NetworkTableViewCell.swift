//
//  NetworkTableViewCell.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/15/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class NetworkTableViewCell: UITableViewCell {
    
    // MARK: Properties
    @IBOutlet weak var name: UILabel!
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
