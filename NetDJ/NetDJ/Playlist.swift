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
    var imageURL: String?
    var image: UIImage?
    weak var state: State!
    var imageHasLoaded = false
    var assignToViewWhenDone = false
    weak var viewToAssign: UIImageView?
    
    // MARK: Initialization
    
    init?(name: String, id: String, selected: Bool, userId: String, imageURL: String?, state: State) {
        
        // Check that name and artist is supplied
        if (id.isEmpty) {
            return nil
        }
        
        // Initialize stored properties
        self.name = name
        self.id = id
        self.selected = selected
        self.imageURL = imageURL
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
    
    @objc func getPic() {
        if let imageURL = self.imageURL {
            if let url = URL(string: imageURL) {
                if let data = try? Data(contentsOf: url) {
                    self.image = UIImage(data: data, scale: UIScreen.main.scale)!
                    self.imageHasLoaded = true
                    if (self.assignToViewWhenDone) {
                        self.assignLoadedPic()
                    }
                }
            }
        } else {
            self.imageHasLoaded = true
        }
    }
    
    func assignPicToView(imageView: UIImageView) {
        imageView.image = self.image
        if (!self.imageHasLoaded) {
            self.viewToAssign = imageView
            self.assignToViewWhenDone = true
            return
        }
    }
    
    func assignLoadedPic() {
        if (self.viewToAssign != nil) {
            DispatchQueue.main.async { [weak self] in
                UIView.animate(withDuration: 0.1, animations: {
                    self?.viewToAssign?.alpha = 0.0
                }, completion: { (finished) in
                    self?.viewToAssign?.image = self?.image
                    UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveLinear, animations: {
                        self?.viewToAssign?.alpha = 1.0
                    }, completion: { (finished) in
                        return
                    })
                })
            }
        }
    }
    
    
}

