//
//  State.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 6/2/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class State {
    
    //MARK: Properties
    
    var group: Group?
    var userId: String!
    var session: SPTSession!
    var player: SPTAudioStreamingController?
    var topSongs = [Song]()
    var hasSong = false
    
    // MARK: Initialization
    
    init?(group: Group?, userId: String!, session: SPTSession!, player: SPTAudioStreamingController?) {
        
        // Initialize stored properties
        self.group = group
        self.userId = userId
        self.session = session
        self.player = player
        self.topSongs = RequestWrapper.getTopSongs(userId: userId, num: 20, session: session)
    }
}
