//
//  Group.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 3/26/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class Group {
    
    //MARK: Properties
    
    var name: String?
    var admin: String
    var id: Int
    var picURL: String?
    var pic = UnsafeMutablePointer<UIImage>.allocate(capacity: 2048)
    var users: [String]?
    var inviteKey: String?
    var songs: [Song]?
    var totalSongs = [Song]()
    var totalSongsFinishedLoading = false
    var network = [[Float]]()
    var totalIds = [String]()
    
    // MARK: Initialization
    
    init?(name: String?, admin: String, id: Int, picURL: String?, users: [String]?, inviteKey: String?) {
        
        // Check that name and artist is supplied
        if (admin.isEmpty) {
            return nil
        }
        
        // Initialize stored properties
        self.name = name
        self.admin = admin
        self.id = id
        self.users = users
        self.inviteKey = inviteKey
        self.picURL = picURL
        
        self.pic.pointee = UIImage(named: Globals.defaultPic)!
        DispatchQueue.global().async {
            if (picURL != nil) {
                let url = URL(string: picURL!)
                if let data = try? Data(contentsOf: url!) {
                    self.pic.pointee = UIImage(data: data)!
                }
            }
        }
    }
}
