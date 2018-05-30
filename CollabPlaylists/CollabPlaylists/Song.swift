//
//  Song.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 3/17/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class Song {
    
     //MARK: Properties
    
    var name: String
    var artist: String
    var id: String
    
    // MARK: Initialization
    
    init?(name: String, artist: String, id: String) {
        
        // Check that name and artist is supplied
        if (name.isEmpty || artist.isEmpty || id.isEmpty) {
            return nil
        }
        
        // Initialize stored properties
        self.name = name
        self.artist = artist
        self.id = id
    }
    
}
