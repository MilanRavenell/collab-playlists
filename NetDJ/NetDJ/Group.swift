//
//  Group.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 3/26/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class Group: NSObject, NSCoding, NSCopying {
    
    //MARK: Properties
    
    var name: String?
    var admin: String!
    var id: Int!
    var picURL: String?
    var pic: UIImage?
    var picHasLoaded = false
    var users = [User]()
    var usersLoaded = false
    var inviteKey: String?
    var songs: [Song]?
    var totalSongs = [Song]()
    var totalSongsFinishedLoading = false
    var network = [[Int]]()
    weak var state: State?
    var isGenerating = false
    var numLoadThreads = 0
    var lock = 0
    var hasLoaded = false
    var cancelLoad = false
    var imageView: UIImageView?
    var isJoining = false
    var queueLoaded = false
    var songsPlayed = [Song]()
    
    // MARK: Initialization
    
    init?(name: String?, admin: String, id: Int, picURL: String?, inviteKey: String?, state: State) {
        super.init()
        // Check that name and artist is supplied
        if (admin.isEmpty) {
            return nil
        }
        
        // Initialize stored properties
        self.name = name
        self.admin = admin
        self.id = id
        self.inviteKey = inviteKey
        self.picURL = picURL
        self.state = state
        self.pic = UIImage(named: Globals.defaultPic)!
        getPic()
    }
    
    required init(coder decoder: NSCoder) {
        super.init()
        self.id = decoder.decodeInteger(forKey: "groupId")
        self.name = decoder.decodeObject(forKey: "groupName") as? String ?? ""
        self.admin = decoder.decodeObject(forKey: "groupAdmin") as? String ?? ""
        self.inviteKey = decoder.decodeObject(forKey: "inviteKey") as? String ?? ""
        self.picURL = decoder.decodeObject(forKey: "groupPicURL") as? String ?? ""
        self.pic = decoder.decodeObject(forKey: "groupPic") as? UIImage ?? UIImage(named: Globals.defaultPic)
        self.songs =  decoder.decodeObject(forKey: "groupFirstSong") as? [Song] ?? [Song]()
        if songs!.count > 0 {
            self.songs = [songs![0]]
        }
        self.picHasLoaded = decoder.decodeObject(forKey: "groupPicHasLoaded") as? Bool ?? false
        if !self.picHasLoaded {
            getPic()
        }
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(id!, forKey: "groupId")
        coder.encode(name, forKey: "groupName")
        coder.encode(admin, forKey: "groupAdmin")
        coder.encode(inviteKey, forKey: "inviteKey")
        coder.encode(picURL, forKey: "groupPicURL")
        coder.encode(pic, forKey: "groupPic")
        coder.encode(songs, forKey: "groupFirstSong")
        coder.encode(picHasLoaded, forKey: "groupPicHasLoaded")
    }
    
    func getPic() {
        DispatchQueue.global().async { [weak self] in
            if let picURL = self?.picURL {
                if let url = URL(string: picURL) {
                    if let data = try? Data(contentsOf: url) {
                        self?.pic = UIImage(data: data, scale: UIScreen.main.scale)!
                        self?.picHasLoaded = true
                        return
                    }
                }
            }
             self?.picHasLoaded = true
        }
    }
    
    func assignPicToView(imageView: UIImageView) {
        self.imageView = imageView
        imageView.image = self.pic
        if (!self.picHasLoaded) {
            DispatchQueue.global().async { [weak self] in
                var picHasLoaded = self?.picHasLoaded
                if picHasLoaded != nil {
                    while(!picHasLoaded!) {
                        picHasLoaded = self?.picHasLoaded
                        if picHasLoaded == nil {
                            return
                        }
                    }
                    DispatchQueue.main.async {
                        UIView.animate(withDuration: 0.1, animations: {
                            imageView.alpha = 0.0
                        }, completion: { (finished) in
                            imageView.image = self?.pic
                            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveLinear, animations: {
                                imageView.alpha = 1.0
                            }, completion: { (finished) in
                                return
                            })
                        })
                    }
                }
            }
        }
    }
    
    func getUsers() {
        let ids = Globals.getGroupUsers(id: self.id)
        
        var users  = [User]()
        for id in ids {
            if (id == self.state!.user.id) {
                users.append(self.state!.user)
            } else {
                let name = Globals.getUsersName(id: id, state: self.state!)
                users.append(User(id: id, name: name)!)
            }
        }
        self.users = users
        usersLoaded = true
        if let groupUsersVC = self.state?.groupUsersVC {
            groupUsersVC.usersDidLoad()
        }
    }
    
    func increaseThreadCount() {
        while (lock == 1) {
        }
        lock = 1
        numLoadThreads += 1
        lock = 0
    }
    
    func decreaseThreadCount() {
        while (lock == 1) {
        }
        lock = 1
        numLoadThreads -= 1
        lock = 0
    }
    
    func update() {
        let groups = Globals.getGroupsById(ids: [id], state: state!)
        if groups.count > 0 {
            let update = groups[0]
            name = update.name
            if update.picURL != picURL {
                picURL = update.picURL
                getPic()
                if imageView != nil {
                    assignPicToView(imageView: imageView!)
                }
            }
            
        }
    }
    
    func unload() {
        if (!totalSongsFinishedLoading) {
            cancelLoad = true
        }
        state!.user.songs[id] = nil
        totalSongs = [Song]()
        network = [[Int]]()
        users = [User]()
        hasLoaded = false
    }
    
    func resetSongs() {
        if self.songs != nil && self.songs!.count > 0 {
            self.songs = [self.songs![0]]
        }
        queueLoaded = false
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Group(name: name, admin: admin, id: id, picURL: nil, inviteKey: inviteKey, state: state!)
        copy?.totalSongs = self.totalSongs
        copy?.network = self.network
        copy?.songs = self.songs
        return copy as Any
    }
    
    func pushToPlayedSongs(song: Song) {
        songsPlayed.append(song)
        if songsPlayed.count > 50 {
            let _ = songsPlayed.removeFirst()
        }
    }
}
