//
//  Song.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 3/17/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class Song: NSObject, NSCoding, NSCopying {
    
     //MARK: Properties
    
    var name: String!
    var artist: String!
    var id: String!
    var imageURL: String?
    var image: UIImage!
    var imageHasLoaded = false
    var saved = false
    var savedHasLoaded = false
    var ticket: (Int, Bool)?
    var assignToViewWhenDone = false
    weak var viewToAssign: UIImageView?
    weak var state: State!
    var cancel = false
    var fromPlaylist: String?
    
    // MARK: Initialization
    
    init?(name: String, artist: String, id: String, imageURL: String?, state: State, loadNow: Bool) {
        super.init()
        // Check that name and artist is supplied
        if (name.isEmpty || id.isEmpty) {
            return nil
        }
        
        // Initialize stored properties
        self.name = name
        self.artist = artist
        self.id = id
        self.imageURL = imageURL
        self.state = state
        
        self.image = UIImage(named: Globals.defaultPic)!
        if (loadNow) {
            self.loadPic()
        }
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "songName")
        coder.encode(id, forKey: "songId")
        coder.encode(artist, forKey: "songArtist")
        coder.encode(imageURL, forKey: "songImageURL")
        coder.encode(image, forKey: "songImage")
        coder.encode(imageHasLoaded, forKey: "songImageHasLoaded")
        coder.encode(savedHasLoaded, forKey: "songSavehasLoaded")
    }
    
    required init?(coder decoder: NSCoder) {
        super.init()
        self.name = decoder.decodeObject(forKey: "songName") as? String ?? ""
        self.id = decoder.decodeObject(forKey: "songId") as? String ?? ""
        self.artist = decoder.decodeObject(forKey: "songArtist") as? String ?? ""
        self.imageURL = decoder.decodeObject(forKey: "songImageURL") as? String ?? ""
        self.image = decoder.decodeObject(forKey: "songImage") as? UIImage ?? UIImage(named: Globals.defaultPic)
        self.imageHasLoaded = decoder.decodeObject(forKey: "songImageHasLoaded") as? Bool ?? false
        self.savedHasLoaded = decoder.decodeObject(forKey: "songSavedHasLoaded") as? Bool ?? false
    }
    
    func loadPic() {
        //state.songLoadQueue?.push(song: self)
        //if (!ticket!.1) {
        DispatchQueue.global().async { [weak self] in
            if let state = self?.state {
                self?.getPic()
//                if let ticket = self?.ticket {
//                    state.songLoadQueue?.pop(queue: ticket.0)
//                    self?.ticket = nil
//                }
            }
        }
        //}
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
    
    func getIsSaved() {
        if let id = self.id {
            if let state = self.state {
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
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Song(name: name, artist: artist, id: id, imageURL: imageURL, state: state, loadNow: false)
        return copy!
    }
}
