//
//  User.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 5/27/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class User {
    
    //MARK: Properties
    
    var id: String
    var name: String?
    var songs = [Int: [Song]]()
    var playlists = [Int: [Playlist]]()
    var topSongs = [Song]()

    
    // MARK: Initialization
    
    init?(id: String, name: String?) {
        
        // Check that name and artist is supplied
        if (id.isEmpty) {
            return nil
        }
        
        // Initialize stored properties
        self.id = id
        self.name = name
    }
}
