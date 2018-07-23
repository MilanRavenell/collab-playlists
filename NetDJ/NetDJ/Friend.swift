//
//  Friend.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/7/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class Friend {
    
    //MARK: Properties
    
    var name: String
    var pic: String?
    var fbId: String
    var chosen: Bool
    
    // MARK: Initialization
    
    init?(name: String, pic: String?, fbId: String) {
        
        // Check that name and artist is supplied
        if (name.isEmpty || fbId.isEmpty) {
            return nil
        }
        
        // Initialize stored properties
        self.name = name
        self.pic = pic
        self.fbId = fbId
        self.chosen = false
    }
    
}

