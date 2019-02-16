//
//  SelectedSongTableViewCell.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 9/2/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class SelectedSongTableViewCell: UITableViewCell {

    var songName: UILabel!
    var songArtist: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        songName = UILabel(frame: CGRect(x: 90, y: contentView.bounds.minY, width: contentView.bounds.width - 90, height: 21))
        songArtist = UILabel(frame: CGRect(x: 90, y: contentView.bounds.minY + 29, width: contentView.bounds.width - 90, height: 21))
        contentView.addSubview(songName)
        contentView.addSubview(songArtist)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
