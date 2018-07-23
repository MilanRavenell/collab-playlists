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
    var selected: Bool
    
    // MARK: Initialization
    
    init?(name: String, id: String, selected: Bool) {
        
        // Check that name and artist is supplied
        if (id.isEmpty) {
            return nil
        }
        
        // Initialize stored properties
        self.name = name
        self.id = id
        self.selected = selected
    }
    
}

