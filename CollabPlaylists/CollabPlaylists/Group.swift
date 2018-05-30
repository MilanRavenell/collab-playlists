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
    var activated: Bool
    var users: [String]?
    
    // MARK: Initialization
    
    init?(name: String?, admin: String, id: Int, activated: Bool, users: [String]?) {
        
        // Check that name and artist is supplied
        if (admin.isEmpty) {
            return nil
        }
        
        // Initialize stored properties
        self.name = name
        self.admin = admin
        self.id = id
        self.activated = activated
        self.users = users
    }
    
}
