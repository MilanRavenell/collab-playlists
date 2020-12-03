//
//  State.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 6/2/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit
//import FacebookCore

class State {
    
    //MARK: Properties
    
    var group: Group?
    var user: User
    var session: SPTSession?
    var sessionManager: SPTSessionManager?
    var appRemote: SPTAppRemote?
    var playerState: SPTAppRemotePlayerState?
    var player: Player?
    //var player: SPTAudioStreamingController?
    var friends = [Friend]()
    var currentActiveGroup: Group?
    var curActiveId: Int?
    var userNetworks = [Int: Group]()
    //var metadata: SPTPlaybackMetadata?
    var groupRequests = [Group]()
    var inviters = [String]()
    var isAtHomeScreen: Bool!
    var numSongsLoaded = 0
    var songLoadQueue = SongLoadQueue(n: 10)
    var loadingSongRange = false
    var groupIds: [Int]?
    var isArchiving = false
    var curCreatingGroup: Group?
    var deviceId: String?
    var accessToken: String!
    var refreshToken: String!
    weak var totalSongsVC: TotalSongsViewController?
    weak var songsVC: SongsViewController?
    weak var userPlaylistVC: UserPlaylistsTableViewController?
    weak var viewPlaylistVC: ViewPlaylistViewController?
    weak var groupUsersVC: GroupUserTableViewController?
    
    // MARK: Initialization
    
    init?(group: Group?, user: User, session: SPTSession?, sessionManager: SPTSessionManager?, appRemote: SPTAppRemote?, accessToken: String, refreshToken: String) {
        
        // Initialize stored properties
        self.group = group
        self.user = user
        self.session = session
        self.sessionManager = sessionManager
        self.appRemote = appRemote
        self.deviceId = "hi"
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        
        self.player = Player(accessToken: accessToken, state: self)
        getDeviceId(accessToken: accessToken)
        
//        appRemote?.playerAPI?.getPlayerState({ [weak self] (playerState, error) in
//            if let error = error {
//                print("Error getting player state:" + error.localizedDescription)
//            } else if let playerState = playerState as? SPTAppRemotePlayerState {
//                self?.playerState = playerState
//            }
//        })
    }
    
    func getAccessToken() -> String {
//        if (!self.session!.isExpired) {
//            return self.session!.accessToken
//        } else {
//            self.session = Globals.renewSession(sessionManager: self.sessionManager!)
//            if (self.session == nil) {
//                print("invalid session")
//                return ""
//            }
//            else {
//                return self.session!.accessToken
//            }
//        }
        if sessionIsExpired() {
            self.accessToken = Globals.renewSession(refreshToken: self.refreshToken)
            return self.accessToken
        } else {
            return self.accessToken
        }
    }
    
    func archiveGroups() {
        isArchiving = true
        DispatchQueue.global().async { [unowned self] in
            NSKeyedArchiver.archiveRootObject(Array(self.userNetworks.values), toFile: Globals.networksFilePath)
            self.isArchiving = false
        }
    }
    
    func sessionIsExpired() -> Bool {
        return true
    }
    
    func getDeviceId(accessToken: String) {
        let query = "https://api.spotify.com/v1/me/player"
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        
        Globals.sendRequest(request: request, postParameters: nil, method: "GET", completion: { [weak self] (response) in
            let responseDict = response as? [String: AnyObject]

            if (responseDict == nil) {
                print("Get deviceId Failed")
                return
            }
            
            if let deviceDict = responseDict?["device"], let id = deviceDict["id"] {
                self?.deviceId = id as? String
            }
        }, isAsync: 0)
    }
}
