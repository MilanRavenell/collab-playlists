//
//  GroupUserTableViewCell.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 3/26/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class GroupUserTableViewCell: UITableViewCell {
    
    //MARK: Properties
    var pic: UIImageView!
    var name: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        pic = UIImageView(frame: CGRect(x: 10, y: contentView.bounds.minY + 5, width: 50, height: contentView.bounds.height - 20))
        
        let path = UIBezierPath(roundedRect: pic.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 10, height: 10))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        pic.layer.mask = mask
        
        pic.contentMode = .scaleAspectFill
        name = UILabel(frame: CGRect(x: pic.frame.maxX + 10, y: contentView.bounds.minY - 5, width: contentView.bounds.width - (pic.frame.maxX + 10), height: contentView.bounds.height))
        
        contentView.addSubview(pic)
        contentView.addSubview(name)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
