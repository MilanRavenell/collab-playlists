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
    var name: String
    var useTop: Int
    
    // MARK: Initialization
    
    init?(id: String, name: String, useTop: Int) {
        
        // Check that name and artist is supplied
        if (id.isEmpty || name.isEmpty) {
            return nil
        }
        
        // Initialize stored properties
        self.id = id
        self.name = name
        self.useTop = useTop
    }
    
}
