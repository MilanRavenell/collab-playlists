//
//  Playlist.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 6/11/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class Playlist: NSObject, NSCoding  {
    //MARK: Properties
    
    var name: String
    var id: String
    var selected: Bool
    var songs: [Song]?
    weak var state: State!
    
    // MARK: Initialization
    
    init?(name: String, id: String, selected: Bool, userId: String, state: State) {
        
        // Check that name and artist is supplied
        if (id.isEmpty) {
            return nil
        }
        
        // Initialize stored properties
        self.name = name
        self.id = id
        self.selected = selected
        self.state = state
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "playlistName")
        coder.encode(id, forKey: "playlistId")
        coder.encode(songs, forKey: "playlistSongs")
    }
    
    required init?(coder decoder: NSCoder) {
        self.name = decoder.decodeObject(forKey: "playlistName") as? String ?? ""
        self.id = decoder.decodeObject(forKey: "playlistId") as? String ?? ""
        self.songs = decoder.decodeObject(forKey: "playlistSongs") as? [Song]
        self.selected = false
    }
    
    func getSongs() -> [Song] {
        if songs == nil {
            if (id == Globals.topSongsToken) {
                songs = Globals.getTopSongs(userId: state.user.id, num: 50, state: state)
            } else {
                songs = Globals.getSongsFromPlaylist(userId: state.user.id, id: id, state: state)
            }
        }
        return songs ?? [Song]()
    }
}

