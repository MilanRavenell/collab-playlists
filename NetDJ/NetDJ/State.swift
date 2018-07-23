//
//  State.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 6/2/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit
import FacebookCore

class State {
    
    //MARK: Properties
    
    var group: Group?
    var user: User
    var session: SPTSession!
    var player: SPTAudioStreamingController?
    var friends = [Friend]()
    var currentActiveGroup: Int?
    var userNetworks = [Int: Group]()
    var metadata: SPTPlaybackMetadata?
    var groupRequests = [Group]()
    
    // MARK: Initialization
    
    init?(group: Group?, user: User, session: SPTSession!, player: SPTAudioStreamingController?) {
        
        // Initialize stored properties
        self.group = group
        self.user = user
        self.session = session
        self.player = player
    }
    
    func getAccessToken() -> String {
        if (self.session.isValid()) {
            return self.session.accessToken
        } else {
            self.session = Globals.renewSession(session: self.session)
            if (self.session == nil) {
                print("invalid session")
                return ""
            }
            else {
                return self.session.accessToken
            }
        }
    }
}
