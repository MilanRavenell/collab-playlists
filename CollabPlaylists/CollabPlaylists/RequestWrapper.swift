//
//  RequestWrapper.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 5/25/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import Foundation

class RequestWrapper {
    
    //MARK: Static Methods
    
    static func loadSongs(numSongs: Int, lastSong: String?, group: Group, session: SPTSession, reuseNetwork: Int) -> [Song] {
        NSLog("LoadSongs")
        var songs = [Song]()
        // Generate Songs
        var query = ""
        if (reuseNetwork == 0) {
            for user in group.users! {
                let songIds = getSongs(userId: user, groupId: group.id)
                if (query == "") {
                    query = user + ":" + songIds
                } else {
                    query = query + ";" + user + ":" + songIds
                }
            }
            query = query + "&\(group.id)&\(numSongs)&0"
        }
        else {
            query = "&\(group.id)&\(numSongs)&1"
        }
        
        if (lastSong == nil) {
            query = query + "&None"
        }
        else {
            query = query + "&\(lastSong!)"
        }
        
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/cgi-bin/GeneratePlaylist.cgi?" + query)
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //setting the method to get
        request.httpMethod = "GET"
        
        let response = sendRequest(request: request, postParameters: nil, method: "GET", isAsync: 0) as! [String: AnyObject]
        
        let songIds = response["songs"] as! [String]
        
        if (songIds.count > 0 && songIds[0] != "") {
            for id in songIds {
                let info = self.getTrackInfo(id: id, session: session)
                let song = Song(name: info.0, artist: info.1, id: id)
                songs.append(song!)
            }
        }
        
        return songs
    }
    
    static func updateNetworkAsync(add_delete: Int, user: String, songs: [Song]) {
        NSLog("LoadSongs")
        // Generate Songs
        var query = "\(add_delete)&" + user + "&"
        for song in songs {
            query += song.id
            query += ";"
        }
        query.removeLast()
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/cgi-bin/UpdateNetwork.cgi?" + query)
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //setting the method to get
        request.httpMethod = "GET"
        
        let _ = sendRequest(request: request, postParameters: nil, method: "GET", isAsync: 1) as! [String: AnyObject]
    }
    
    static func getSongs(userId: String, groupId: Int) -> String {
        NSLog("GetSongs")
        
        var songIds = ""
        var numSongs = 0
        
        let requestURL = URL(string: "http://autocollabservice.com/getusersongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "userId=" + userId + "&groupId=\(groupId)&onlyAdded=0"
        
        let response = sendRequest(request: request, postParameters: postParameters, method: "POST", isAsync: 0) as! [String: AnyObject]
        
        let songs = response["songs"]! as! [[AnyObject]]
        
        for song in songs {
            numSongs += 1
            let id = song[0] as! String
            if (songIds == "") {
                songIds = id
            } else {
                songIds = songIds + "," + id
            }
        }
        return songIds
        
    }
    
    static func getTrackInfo(id: String, session: SPTSession) -> (String, String) {
        NSLog("TrackInfo")
        
        let url = URL(string: "spotify:track:\(id)")
        
        let request = try? SPTTrack.createRequest(forTrack: url, withAccessToken: session.accessToken, market: nil)
        
        if (request == nil) {
            NSLog("failed")
            return ("None","None")
        }
        
        let response = sendRequest(request: request as! NSMutableURLRequest, postParameters: nil, method: "GET", isAsync: 0) as! [String: AnyObject]
        
        let name = response["name"] as! String
        let artists = response["artists"] as? [[String: AnyObject]]
        var artistName =  artists?[0]["name"] as? String
        if (artistName == nil) {
            artistName = "Not Found"
        }
        return (name, artistName!)
    }
    
    static func deletePlaylist(group: Group) {
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/deleteplaylist")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(group.id)"
        
        let _ = sendRequest(request: request, postParameters: postParameters, method: "POST", isAsync: 0) as! [String: AnyObject]
    }
    
    static func addPlaylistSongs(songs: [Song], group: Group) {
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/addplaylistsongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        var songIds = ""
        var songNames = ""
        var songArtists = ""
        
        for song in songs {
            songIds += String(song.id)
            songIds += "///"
            songNames += String(song.name)
            songNames += "///"
            songArtists += String(song.artist)
            songArtists += "///"
        }
        
        if songs.count > 0 {
            songIds.removeLast(3)
            songNames.removeLast(3)
            songArtists.removeLast(3)
        }
        
        songNames = songNames.replacingOccurrences(of: "&", with: "and")
        songArtists = songArtists.replacingOccurrences(of: "&", with: "and")
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(group.id)&songIds=" + songIds + "&songNames=" + songNames + "&songArtists=" + songArtists
        
        let _ = sendRequest(request: request, postParameters: postParameters, method: "POST", isAsync: 0) as! [String: AnyObject]
    }
    
    static func addGroupUser(groupId: Int, userId: String) {
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/addgroupuser")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(groupId)" + "&userId=" + userId
        
        let _ = sendRequest(request: request , postParameters: postParameters, method: "POST", isAsync: 0) as! [String: AnyObject]
    }
    
    static func getTopSongs(userId: String, num: Int, session: SPTSession) -> [Song] {
        var additionalTracks = [Song]()
        let query = "https://api.spotify.com/v1/me/top/tracks?limit=\(num)"
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(session.accessToken!)", forHTTPHeaderField: "Authorization")
        
        let response = sendRequest(request: request, postParameters: nil, method: "GET", isAsync: 0) as! [String: AnyObject]
        
        let tracks = response["items"] as! [[String: AnyObject]]
        for track in tracks {
            let id = track["id"] as! String
            let name = track["name"] as! String
            let artists = track["artists"] as? [[String: AnyObject]]
            var artistName =  artists?[0]["name"] as? String
            if (artistName == nil) {
                artistName = "Not Found"
            }
            let newSong = Song(name: name, artist: artistName!, id: id)
            additionalTracks.append(newSong!)
        }
        
        return additionalTracks
    }
    
    static func addUserSongs(songs: [Song], userId: String, groupId: Int, isTop: Int) {
        
        let requestURL = URL(string: "http://autocollabservice.com/addusersongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        var songIds = ""
        var songNames = ""
        var songArtists = ""
        
        for song in songs {
            songIds += String(song.id)
            songIds += "///"
            songNames += String(song.name)
            songNames += "///"
            songArtists += String(song.artist)
            songArtists += "///"
        }
        
        if songs.count > 0 {
            songIds.removeLast(3)
            songNames.removeLast(3)
            songArtists.removeLast(3)
        }
        
        songNames = songNames.replacingOccurrences(of: "&", with: "and")
        songArtists = songArtists.replacingOccurrences(of: "&", with: "and")
        
        //creating the post parameter by concatenating the keys and values from text field
        var postParameters = "groupId=\(groupId)" + "&userId=" + userId
        postParameters += "&songIds=" + songIds
        postParameters += "&songNames=" + songNames
        postParameters += "&songArtists=" + songArtists
        postParameters += "&isTop=\(isTop)"
        
        let _ = sendRequest(request: request, postParameters: postParameters, method: "POST", isAsync: 0)
    }
    
    static func deleteUserSongs(songs: [Song], userId: String, groupId: Int) {
        
        let requestURL = URL(string: "http://autocollabservice.com/deleteusersongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        var songIds = ""
        
        for song in songs {
            songIds += String(song.id)
            songIds += "///"
        }
        
        if songs.count > 0 {
            songIds.removeLast(3)
        }
        
        //creating the post parameter by concatenating the keys and values from text field
        var postParameters = "groupId=\(groupId)" + "&userId=" + userId
        postParameters += "&songIds=" + songIds
        
        let _ = sendRequest(request: request, postParameters: postParameters, method: "POST", isAsync: 0)
    }
    
    static func getGroupUsers(id: Int) -> [String] {
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getgroupusers")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(id)"
        
        let response = sendRequest(request: request, postParameters: postParameters, method: "POST", isAsync: 0) as! [String: [String]]
        
        return response["users"]!
    }
    
    static func sendRequest(request: NSMutableURLRequest, postParameters: String?, method: String, isAsync: Int) -> AnyObject? {
        //setting the method to post
        request.httpMethod = method
        
        if (method == "POST") {
            //adding the parameters to request body
            request.httpBody = postParameters!.data(using: String.Encoding.utf8)
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        
        var JSON: AnyObject?
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if error != nil{
                print("error is \(String(describing: error))")
                return;
            }
            
            //parsing the response
            do {
                //converting resonse to NSDictionary
                JSON  = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as AnyObject
                
            } catch {
                print("\(error)")
            }
            if (isAsync == 0) {
                semaphore.signal()
            }
        }
        //executing the
        task.resume()
        if (isAsync == 0) {
            _ = semaphore.wait(timeout: .distantFuture)
        }
        return JSON
    }
}


