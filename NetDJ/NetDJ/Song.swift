//
//  Song.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 3/17/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class Song {
    
     //MARK: Properties
    
    var name: String
    var artist: String
    var id: String
    var imageURL: String?
    var image: UIImage!
    var imageHasLoaded = false
    var saved = false
    var savedHasLoaded = false
    
    // MARK: Initialization
    
    init?(name: String, artist: String, id: String, imageURL: String?, state: State) {
        
        // Check that name and artist is supplied
        if (name.isEmpty || id.isEmpty) {
            return nil
        }
        
        // Initialize stored properties
        self.name = name
        self.artist = artist
        self.id = id
        self.imageURL = imageURL
        
        self.image = UIImage(named: Globals.defaultPic)!
        DispatchQueue.global().async {
            if (imageURL != nil) {
                let url = URL(string: imageURL!)
                if let data = try? Data(contentsOf: url!) {
                    self.image = UIImage(data: data)!
                    self.imageHasLoaded = true
                }
            } else {
                self.imageHasLoaded = true
            }
            
            Globals.isSongSaved(id: id, state: state, completion: { (response) in
                let saved = response as? [Bool]
                if (saved == nil) {
                    return
                }
                self.saved = saved![0]
                self.savedHasLoaded = true
            })
        }
    }
}
