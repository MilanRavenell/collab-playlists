//
//  PlaylistSongTableViewCell.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 4/10/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class PlaylistSongTableViewCell: UITableViewCell {
    
    //MARK: Properties
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var artist: UILabel!
    var albumCover: UIImageView!
    var originalNameFrame: CGRect!
    var originalAritstFrame: CGRect!
    var originalAlbumFrame: CGRect!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        albumCover = UIImageView(frame: CGRect(x: 0, y: 0, width: 80, height: contentView.frame.height))
        contentView.addSubview(albumCover)
        
        originalNameFrame = name.frame
        originalAritstFrame = artist.frame
        originalAlbumFrame = albumCover.frame
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        name.frame = CGRect(x: originalNameFrame.minX - 40, y: originalNameFrame.minY, width: originalNameFrame.width - 30, height: originalNameFrame.height)
        artist.frame = CGRect(x: originalAritstFrame.minX - 40, y: originalAritstFrame.minY, width: originalAritstFrame.width - 30, height: originalAritstFrame.height)
        albumCover.frame = CGRect(x: originalAlbumFrame.minX - 40, y: originalAlbumFrame.minY, width: originalAlbumFrame.width, height: originalAlbumFrame.height)
    }
}
