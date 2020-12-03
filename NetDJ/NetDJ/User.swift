//
//  User.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 5/27/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit
//import FacebookCore
//import FacebookLogin
//import FBSDKLoginKit

class User {
    
    //MARK: Properties
    
    var id: String
    var name: String?
    var songs = [Int: [Song]]()
    var selectedPlaylists = [Int: [String]]()
    var picURL: String?
    var pic: UIImage?
    var picHasLoaded = false
    var savedSongs = Set([String]())
    var imageView: UIImageView!
    var songsHasLoaded = false
    weak var state: State!
    var defaultsLoaded = false

    
    // MARK: Initialization
    
    init?(id: String, name: String?) {
        
        // Check that name and artist is supplied
        if (id.isEmpty) {
            return nil
        }
        
        // Initialize stored properties
        self.id = id
        self.name = name
        self.pic = UIImage(named: Globals.defaultPic)
        
        DispatchQueue.global().async { [weak self] in
            self?.getProfPic()
        }
    }
    
    func assignPicToView(imageView: UIImageView, animated: Bool) {
        DispatchQueue.main.async { [weak self] in
            imageView.image = self?.pic
        }
        if !picHasLoaded {
            self.imageView = imageView
            return
        }
        if animated {
            DispatchQueue.global().async { [weak self] in
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
        } else {
            imageView.image = self.pic
            self.imageView = nil
        }
    }
    
    // Picture order: NetDJ pic -> FB Pic -> SpotifyPix
    func getProfPic() {
        picHasLoaded = false
        if (!tryGetUserPic()) {
            tryGetFbPic()
        }
    }
    
    func tryGetUserPic() -> Bool {
        let userPicURL = Globals.getUserPic(userId: id)
        if (userPicURL == nil) {
            return false
        }
        let url = URL(string: userPicURL!)
        if let data = try? Data(contentsOf: url!) {
            self.pic = UIImage(data: data, scale: UIScreen.main.scale)
            picHasLoaded = true
            if let imageView = imageView {
                assignPicToView(imageView: imageView, animated: true)
            }
            return true
        }
        return false
    }
    
    func tryGetFbPic() {
        let fbIds = Globals.getFbIds(users: [id])
        var fbId = ""
        if fbIds.count > 0 {
            fbId = Globals.getFbIds(users: [id])[0]
        } else {
            return
        }
        
        var pic: String?
        
        let params = ["fields": "picture.type(large)"]
        
        //let graphrequest = GraphRequest(graphPath: "/" + fbId, parameters: params, tokenString: AccessToken.current?.tokenString, version: "GET", httpMethod: .get)
        
//        graphrequest.start( completionHandler: { [weak self] (urlResponse, requestResult) -> Void in
//            switch requestResult {
//            case .failed(let error):
//                print("error:", error)
//                self?.picHasLoaded = true
//                break
//            case .success(let graphResponse):
//                if let responseDictionary = graphResponse.dictionaryValue {
//                    pic = ((responseDictionary["picture"] as? [String: AnyObject])?["data"] as? [String: AnyObject])?["url"] as? String
//
//                    if (pic != nil) {
//                        if let url = URL(string: pic!) {
//                            DispatchQueue.global().async {
//                                let data = try? Data(contentsOf: url) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
//                                DispatchQueue.main.async {
//                                    self?.pic = UIImage(data: data!, scale: UIScreen.main.scale)
//                                    self?.picHasLoaded = true
//                                    if let imageView = self?.imageView {
//                                        self?.assignPicToView(imageView: imageView, animated: true)
//                                    }
//                                }
//                                return
//                            }
//                        }
//                    }
//                    self?.picHasLoaded = true
//                }
//            }
//        })
    }
    
    func getPlaylists(state: State) {
        let playlists = Globals.getUserPlaylists(userId: self.id, state: state)
        NSKeyedArchiver.archiveRootObject(playlists, toFile: Globals.playlistsFilePath)
    }
    
    func getSavedSongs(state: State) {
        var query = "https://api.spotify.com/v1/me/tracks?limit=50"
        var url = URL(string: query)
        var request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(state.getAccessToken())", forHTTPHeaderField: "Authorization")
        
        var didTimeOut = false
        while query != "Done!" && !didTimeOut{
            didTimeOut = true
            Globals.sendRequest(request: request, postParameters: nil, method: "GET", completion: { [weak self] (response) in
                didTimeOut = false
                if let response = response as? [String: AnyObject] {
                    let items = response["items"] as? [[String: AnyObject]] ?? []
                    for item in items {
                        let track = item["track"] as? [String: AnyObject] ?? [String: AnyObject]()
                        let id = track["id"] as? String ?? ""
                        self?.savedSongs.insert(id)
                    }
                    query = response["next"] as? String ?? "Done!"
                    url = URL(string: query)
                    request = NSMutableURLRequest(url: url!)
                    request.setValue("Bearer \(state.getAccessToken())", forHTTPHeaderField: "Authorization")
                    
                } else {
                    query = "Done!"
                }
            }, isAsync: 0)
        }
    }
}
