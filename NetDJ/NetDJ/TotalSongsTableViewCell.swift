//
//  TotalSongsTableViewCell.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/17/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class TotalSongsTableViewCell: UITableViewCell {

    // MARK: Properies
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var artist: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let buttonsLabel = UILabel(frame: CGRect(x: contentView.frame.width + 80, y: contentView.frame.minY, width: 40, height: contentView.frame.height))
        buttonsLabel.text = "..."
        contentView.addSubview(buttonsLabel)

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
