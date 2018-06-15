//
//  Playlist.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 6/11/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class Playlist {
    
    //MARK: Properties
    
    var name: String
    var id: String
    
    // MARK: Initialization
    
    init?(name: String, id: String) {
        
        // Check that name and artist is supplied
        if (name.isEmpty || id.isEmpty) {
            return nil
        }
        
        // Initialize stored properties
        self.name = name
        self.id = id
    }
    
}

