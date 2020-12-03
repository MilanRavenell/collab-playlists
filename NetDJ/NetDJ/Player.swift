//
//  Player.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 11/30/20.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit
//import FacebookCore

class Player {
    
    //MARK: Properties
    
    var accessToken: String
    var state: State!
    
    // MARK: Initialization
    
    init?(accessToken: String, state: State) {
        
        // Initialize stored properties
        self.accessToken = accessToken
        self.state = state
    }
    
    func playSong(songId: String) {
        let query = "https://api.spotify.com/v1/me/player/play?device_id=" + self.state.deviceId!
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        let putParameters = "uris=spotify:track:" + songId
        request.setValue("Bearer \(self.state!.getAccessToken())", forHTTPHeaderField: "Authorization")
        
        Globals.sendRequest(request: request, postParameters: putParameters, method: "PUT", completion: { _ in }, isAsync: 1)
    }
    
    func pause() {
        let query = "https://api.spotify.com/v1/me/player/pause?device_id=" + self.state.deviceId!
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(self.state!.getAccessToken())", forHTTPHeaderField: "Authorization")
        
        Globals.sendRequest(request: request, postParameters: nil, method: "PUT", completion: { _ in }, isAsync: 1)
    }
    
    func seek(position: Int) {
        //Position in milliseconds
        let query = "https://api.spotify.com/v1/me/player/seek?device_id=" + self.state.deviceId! + "&position_ms=" + String(position)
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(self.state!.getAccessToken())", forHTTPHeaderField: "Authorization")
        
        Globals.sendRequest(request: request, postParameters: nil, method: "PUT", completion: { _ in }, isAsync: 1)
    }
    
    func isPlaying() -> Bool {
        let query = "https://api.spotify.com/v1/me/player/currently-playing"
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(self.state!.getAccessToken())", forHTTPHeaderField: "Authorization")
        
        var is_playing = false
        
        Globals.sendRequest(request: request, postParameters: nil, method: "GET", completion: { (response) in
            let responseDict = response as? [String: AnyObject]

            if (responseDict == nil) {
                print("Get isPlaying Failed")
                return
            }
            
            is_playing = responseDict!["is_playing"] as? Bool ?? false
        }, isAsync: 0)
        
        return is_playing
    }
}
