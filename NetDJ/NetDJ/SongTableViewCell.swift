//
//  SongTableViewCell.swift
//  
//
//  Created by Milan Ravenell on 7/16/18.
//

import UIKit

class SongTableViewCell: UITableViewCell {

    // MARK: Properties
    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var songArtist: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
