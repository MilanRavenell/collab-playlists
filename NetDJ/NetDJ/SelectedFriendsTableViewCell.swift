//
//  SelectedFriendsTableViewCell.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/4/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class SelectedFriendsTableViewCell: UITableViewCell {

    //MARK: Properties
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
