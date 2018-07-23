//
//  Globals.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 5/25/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import Foundation
import FacebookCore
import FacebookLogin
import FBSDKLoginKit

class Globals {
    
    //MARK: Static Properties
    static let topSongsToken = "///TOPSONGS///"
    static let defaultPic = "netDJ_5_default.png"
    static let smallOffset: CGFloat = 5
    static let medOffset: CGFloat = 15
    static let bigOffset: CGFloat = 35
    
    //MARK: Static Methods    
    static func generateSongs(groupId: Int, numSongs: Int, lastSong: String?, state: State) -> [Song] {

        var songs = [Song]()
        // Generate Songs
        if (numSongs <= 0) {
            return songs
        }
        
        var query = ""
        if (lastSong == nil) {
            query = "\(groupId)&" + String(numSongs) + "&None"
        } else {
            query = "\(groupId)&" + String(numSongs) + "&\(lastSong!)"
        }
        // Prevent getting cached response
        query += "&" + randomString(length: 5)
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/cgi-bin/GeneratePlaylist.cgi?" + query)
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        var responseDict: [String: AnyObject]?
        
        sendRequest(request: request, postParameters: nil, method: "GET", completion: { (response) in
            responseDict = response as? [String: AnyObject]
        }, isAsync: 0)
        
        if (responseDict == nil) {
            return []
        }
        
        let songIds = responseDict!["songs"] as! [String]
        
        if (songIds.count > 0 && songIds[0] != "") {
            for id in songIds {
                let info = self.getTrackInfo(id: id, state: state)
                let song = Song(name: info.0, artist: info.1, id: id, imageURL: info.2, state: state)
                songs.append(song!)
            }
        }
        
        return songs
    }
    
    static func updateNetworkAsync(groupId: Int, add_delete: Int, user: String, songs: [Song]) {
        NSLog("LoadSongs")
        // Generate Songs
        var query = "\(groupId)&\(add_delete)&" + user + "&"
        if (songs.count > 0){
            for song in songs {
                query += song.id
                query += ";"
            }
            query.removeLast()
        } else {
            query += "None"
        }

        // To prevent using cache
        query += "&" + randomString(length: 5)

        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/cgi-bin/UpdateNetwork.cgi?" + query)

        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)

        //setting the method to get
        request.httpMethod = "GET"

        sendRequest(request: request, postParameters: nil, method: "GET", completion: {_ in}, isAsync: 1)

    }
    
    static func updateNetwork(group: Group, state: State) {
        let (songDict, totalSongs, totalIds) = getSongsDict(groupId: group.id, state: state)
        
        let topSongs = HITS.getTopAuth(auth: HITS.HITS(songDict: songDict, t: 100), n: 50)
        let network = HITS.generateGraph(songIdsTotal: totalIds, songDict: songDict, clusters: [[String]](), topAuth: topSongs)
        
        group.network = network
        group.totalSongs = totalSongs
        group.totalIds = totalIds
    }
    
    static func generateSongs2(group: Group, numSongs: Int, lastSong: String?, state: State) -> [Song] {
        let network = group.network
        
        var start = ""
        var ids = [String]()
        var songs = [Song]()
        var n = numSongs
        
        if (lastSong == nil) {
            start = HITS.getRandSong(songs: group.totalIds, dist: [Float](repeating: 1, count: group.totalIds.count))
            ids.append(start)
            n -= 1
        } else {
            start = lastSong!
        }
        
        let (newSongs, newNetwork) = HITS.getNextSongs(network: network, start: start, songs: group.totalIds, n: n)
        ids.append(contentsOf: newSongs)
        
        for id in ids {
            let info = self.getTrackInfo(id: id, state: state)
            let song = Song(name: info.0, artist: info.1, id: id, imageURL: info.2, state: state)
            songs.append(song!)
        }
        
        group.network = newNetwork
        return songs
    }
    
    static func getSongsDict(groupId: Int, state: State) -> ([String: [Song]], [Song], [String]) {
        var songsDict = [String: [Song]]()
        var totalSongs = [Song]()
        var totalIds = Set<String>()
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/gettotalsongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        //creating the post parameter by concatenating the keys and values from text field
        
        let postParameters = "groupId=\(groupId)"
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (response) in
            let responseDict = response as? [String: [[AnyObject]]]
            
            let responseSongs = responseDict?["songs"]
            if (responseSongs != nil) {
                for song in responseSongs! {
                    let name = song[1] as! String
                    let artist = song[2] as! String
                    let id = song[0] as! String
                    let albumCover = song[5] as? String
                    let user = song[3] as! String
                    let newSong = Song(name: name, artist: artist, id: id, imageURL: albumCover, state: state)
                    
                    if (!totalIds.contains(id)) {
                        totalIds.insert(id)
                        totalSongs.append(newSong!)
                    }
                    songsDict[user]!.append(newSong!)
                }
            }
        }, isAsync: 0)
        return (songsDict, totalSongs, Array(totalIds))
    }
    
    static func getTokens(code: String) -> (String, String) {
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/swap")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "code=" + code
        
        var accessToken = ""
        var refreshToken = ""
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (response) in
            let responseDict = response as? [String: AnyObject]
            
            if (responseDict == nil) {
                print("authorization failed!")
                return
            }
            accessToken = responseDict!["access_token"] as! String
            refreshToken = responseDict!["refresh_token"] as! String
        }, isAsync: 0)
        
        return (accessToken, refreshToken)
    }
    
    static func createUser(userId: String, refreshToken: String) {
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/createuser")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "spotifyId=" + userId + "&refreshToken=" + refreshToken
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {_ in}, isAsync: 1)
    }
    
    static func renewSession(session: SPTSession) -> SPTSession? {
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/refresh")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "refresh_token=" + session.encryptedRefreshToken
        
        var newSession: SPTSession?
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (response) in
            let responseDict = response as? [String: AnyObject]
            
            if (responseDict == nil) {
                print("authorization failed!")
                return
            }
            let accessToken = responseDict!["access_token"] as! String
            newSession = SPTSession(userName: session.canonicalUsername, accessToken: accessToken, encryptedRefreshToken: session.encryptedRefreshToken, expirationDate: Date(timeIntervalSinceNow: 3600))
            
        }, isAsync: 0)
        
        return newSession
    }
    
    static func createGroup(userId: String) -> (Int, String) {
        let requestURL = URL(string: "http://autocollabservice.com/creategroup")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        let inviteKey = randomString(length: 15)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "admin=" + userId + "&inviteKey=" + inviteKey
        
        //adding the parameters to request body
        request.httpBody = postParameters.data(using: String.Encoding.utf8)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        var responseDict: [String: AnyObject]?
        
        sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (response) in
            responseDict = response as? [String: AnyObject]
        }, isAsync: 0)
        
        if (responseDict == nil) {
            return (-2, "None")
        }
        let groupId = responseDict!["groupId"] as! Int
        
        return (groupId, inviteKey)
    }
    
    static func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    static func getGroupsById(ids: [Int]) -> [Group] {
        
        var groups = [Group]()
        
        if (ids == []) {
            return []
        }
        
        var ids_str = ""
        for id in ids {
            if (id != -2) {
                ids_str += String(id)
                ids_str += ","
            }
        }
        if ids.count > 0 {
            ids_str.removeLast()
        }
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getgroups")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        let postParameters = "method=id" + "&groupIds=" + ids_str
        
        var responseGroups: [[String: AnyObject]]?
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (response) in
            responseGroups = response as? [[String: AnyObject]]
        }, isAsync: 0)
        
        if (responseGroups == nil) {
            return []
        }
        
        for group in responseGroups! {
            NSLog("group")
            let name = group["name"] as? String
            let admin = group["admin"] as! String
            let id = group["id"] as! Int
            let inviteKey = group["invite_key"] as! String
            let picURL = group["pic"] as? String
            
            let newGroup = Group(name: name, admin: admin, id: id, picURL: picURL, users:[], inviteKey: inviteKey)
            groups.append(newGroup!)
        }
        
        for group in groups {
            group.users = Globals.getGroupUsers(id: group.id)
        }
        
        return groups
    }
    
    static func getSongs(userId: String, groupId: Int) -> String {
        NSLog("GetSongs")
        
        var songIds = ""
        var numSongs = 0
        
        let requestURL = URL(string: "http://autocollabservice.com/getusersongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "userId=" + userId + "&groupId=\(groupId)"
        
        var songs: [[AnyObject]]?
        
        sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {(response) in
            let responseDict = response as? [String: AnyObject]
            songs = responseDict?["songs"] as? [[AnyObject]]
        }, isAsync: 0)
        
        if (songs == nil) {
            return ""
        }
        
        for song in songs! {
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
    
    static func getTrackInfo(id: String, state: State) -> (String, String, String?) {
        NSLog("TrackInfo")
        
        let url = URL(string: "spotify:track:\(id)")
        
        let request = try? SPTTrack.createRequest(forTrack: url, withAccessToken: state.getAccessToken(), market: nil)
        
        if (request == nil) {
            NSLog("failed")
            return ("None","None", nil)
        }
        
        var name: String?
        var artistName: String?
        var albumCover: String?
        
        sendRequest(request: request as! NSMutableURLRequest, postParameters: nil, method: "GET", completion: { (response) in
            let responseDict = response as? [String: AnyObject]
             name = responseDict?["name"] as? String
            let artists = responseDict?["artists"] as? [[String: AnyObject]]
             artistName =  artists?[0]["name"] as? String
            let album = responseDict?["album"] as? [String: AnyObject]
            let pictures = album?["images"] as? [[String: AnyObject]]
            albumCover = pictures?[0]["url"] as? String
        }, isAsync: 0)
        
        if (name == nil) {
            name = "Not Found"
        }
        if (artistName == nil) {
            artistName = "Not Found"
        }
        return (name!, artistName!, albumCover)
    }
    
    static func isSongSaved(id: String, state: State, completion: @escaping (AnyObject?) -> Void){
        let query = "https://api.spotify.com/v1/me/tracks/contains?ids=" + id
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(state.getAccessToken())", forHTTPHeaderField: "Authorization")
        
        var isSaved: [Bool]?
        sendRequest(request: request, postParameters: nil, method: "GET", completion: completion, isAsync: 1)
    }
    
    static func deletePlaylist(groupId: Int, userId: String) {
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/deleteplaylist")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(groupId)&userId=" + userId
        
        sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {_ in}, isAsync: 0)
    }
    
    // Add 10 songs at a time, inherently deletes current playlist in database
    static func addPlaylistSongs(songs: [Song], groupId: Int, userId: String) {
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/addplaylistsongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        var songIds = ""
        var songNames = ""
        var songArtists = ""
        var albumCovers = ""
        
        for song in songs {
            songIds += String(song.id)
            songIds += "///"
            songNames += String(song.name)
            songNames += "///"
            songArtists += String(song.artist)
            songArtists += "///"
            if (song.imageURL != nil) {
                albumCovers += String(song.imageURL!)
            }
            else {
                albumCovers += "None"
            }
            
            albumCovers += "///"
        }
        
        if songs.count > 0 {
            songIds.removeLast(3)
            songNames.removeLast(3)
            songArtists.removeLast(3)
            albumCovers.removeLast(3)
        }
        
        songNames = songNames.replacingOccurrences(of: "&", with: "and")
        songArtists = songArtists.replacingOccurrences(of: "&", with: "and")
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(groupId)&songIds=" + songIds + "&songNames=" + songNames + "&songArtists=" + songArtists + "&albumCovers=" + albumCovers + "&userId=" + userId
        
        sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {_ in}, isAsync: 1)
    }
    
    static func addGroupUsers(groupId: Int, userIds: [String]) {
        
        var usersStr = ""
        for id in userIds {
            usersStr += id
            usersStr += "///"
        }
        if (userIds.count > 0) {
            usersStr.removeLast(3)
        }
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/addgroupusers")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(groupId)" + "&userIds=" + usersStr
        
        sendRequest(request: request , postParameters: postParameters, method: "POST", completion:{_ in}, isAsync: 1)
    }
    
    static func deleteGroupUser(userId: String, groupId: Int) {
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/deletegroupuser")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(groupId)" + "&userId=" + userId
        
        sendRequest(request: request, postParameters: postParameters, method: "POST", completion:  {_ in}, isAsync: 1)
    }
    
    static func deleteUserFromGroup(userId: String, groupId: Int) {
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/deleteuserfromgroup")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(groupId)" + "&userId=" + userId
        
        sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {_ in}, isAsync: 0)
    }
    
    static func getTopSongs(userId: String, num: Int, state: State) -> [Song] {
        var additionalTracks = [Song]()
        let query = "https://api.spotify.com/v1/me/top/tracks?limit=\(num)"
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(state.getAccessToken())", forHTTPHeaderField: "Authorization")
        
        var tracks: [[String: AnyObject]]?
        sendRequest(request: request, postParameters: nil, method: "GET", completion: { (response) in
            let responseDict = response as? [String: AnyObject]
            tracks = responseDict!["items"] as? [[String: AnyObject]]
        }, isAsync: 0)
        
        if (tracks == nil) {
            return []
        }
        
        for track in tracks! {
            let id = track["id"] as! String
            let name = track["name"] as! String
            let artists = track["artists"] as? [[String: AnyObject]]
            var artistName =  artists?[0]["name"] as? String
            let album = track["album"] as! [String: AnyObject]
            let pictures = album["images"] as? [[String: AnyObject]]
            let albumCover = pictures?[0]["url"] as? String
            if (artistName == nil) {
                artistName = "Not Found"
            }
            let newSong = Song(name: name, artist: artistName!, id: id, imageURL: albumCover, state: state)
            additionalTracks.append(newSong!)
        }
        
        return additionalTracks
    }
    
    static func addUserSongs(songs: [Song], userId: String, group: Group, fromPlaylist: Int) {
        
        var songIds = ""
        var songNames = ""
        var songArtists = ""
        var albumCovers = ""
        
        for song in songs {
            songIds += String(song.id)
            songIds += "///"
            songNames += String(song.name)
            songNames += "///"
            songArtists += String(song.artist)
            songArtists += "///"
            if (song.imageURL == nil) {
                albumCovers += "None"
            } else {
                albumCovers += String(song.imageURL!)
            }
            albumCovers += "///"
        }
        
        if songs.count > 0 {
            songIds.removeLast(3)
            songNames.removeLast(3)
            songArtists.removeLast(3)
            albumCovers.removeLast(3)
        }
        
        songNames = songNames.replacingOccurrences(of: "&", with: "and")
        songArtists = songArtists.replacingOccurrences(of: "&", with: "and")
        
        let requestURL = URL(string: "http://autocollabservice.com/addusersongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        var postParameters = "groupId=\(group.id)" + "&userId=" + userId
        postParameters += "&ids=" + songIds
        postParameters += "&names=" + songNames
        postParameters += "&artists=" + songArtists
        postParameters += "&albumCovers=" + albumCovers
        postParameters += "&fromPlaylist=" + String(fromPlaylist)
        
        sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {_ in }, isAsync: 0)
    }
    
    static func addUserPlaylist(playlist: Playlist, userId: String, groupId: Int) {
        let requestURL = URL(string: "http://autocollabservice.com/adduserplaylist")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        let postParameters = "playlistId=" + playlist.id + "&userId=" + userId + "&groupId=\(groupId)&playlistName=" + playlist.name
        
        sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {_ in}, isAsync: 0)
    }
    
    static func getUserPlaylists(userId: String, groupId: Int, state: State) -> [Playlist] {
        
        var selectedIds = [String]()
        for playlist in Globals.getUserSelectedPlaylists(userId: userId, groupId: groupId) {
            selectedIds.append(playlist.id)
        }
        
        var playlists = [Playlist]()
        
        // Get rest of playlists
        let query = "https://api.spotify.com/v1/users/" + userId + "/playlists"
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(state.getAccessToken())", forHTTPHeaderField: "Authorization")
        
        var responsePlaylists: [[String: AnyObject]]?
        
        sendRequest(request: request, postParameters: nil, method: "GET", completion: { (response) in
            let responseDict = response as? [String: AnyObject]
            responsePlaylists = responseDict?["items"] as? [[String : AnyObject]]
        }, isAsync: 0)
        
        if (responsePlaylists == nil) {
            return []
        }

        for playlist in responsePlaylists! {
            let id = playlist["id"] as! String
            let name = playlist["name"] as! String
            
            var newPlaylist: Playlist?
            if (selectedIds.contains(id)) {
                newPlaylist = Playlist(name: name, id: id, selected: true)
            } else {
                newPlaylist = Playlist(name: name, id: id, selected: false)
            }
            
            playlists.append(newPlaylist!)
        }
        
        playlists.insert(Playlist(name: "Use My Top Songs", id: Globals.topSongsToken, selected: selectedIds.contains(Globals.topSongsToken))!, at: 0)
        
        return playlists
    }
    
    static func deleteUserPlaylist(id: String, userId: String, groupId: Int) {
        let requestURL = URL(string: "http://autocollabservice.com/deleteuserplaylist")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        var postParameters = "playlistId=" + id + "&userId=" + userId
        postParameters += "&groupId=\(groupId)"
        
        sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {_ in }, isAsync: 1)
    }
    
    static func deleteUserSongs(songs: [Song], userId: String, groupId: Int) {
        
        let requestURL = URL(string: "http://autocollabservice.com/deleteusersongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        var ids = ""
        for song in songs {
            ids += song.id
            ids += "///"
        }
        if (songs.count > 0) {
            ids.removeLast(3)
        }
        
        //creating the post parameter by concatenating the keys and values from text field
        var postParameters = "groupId=\(groupId)" + "&userId=" + userId
        postParameters += "&ids=" + ids
        
        sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {_ in }, isAsync: 0)
    }
    
    static func getGroupUsers(id: Int) -> [String] {
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getgroupusers")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(id)"
        
        var responseDict: [String: [String]]?
        sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (response) in
            responseDict = response as? [String: [String]]
        },isAsync: 0)
        
        if (responseDict == nil) {
            return []
        }
        
        return responseDict!["users"]!
    }
    
    static func deleteGroup(group: Group) {
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/deletegroup")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(group.id)"
        
        //adding the parameters to request body
        request.httpBody = postParameters.data(using: String.Encoding.utf8)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { _ in }, isAsync: 0)
    }
    
    static func getUsersName(id: String, state: State) -> String {
        let query = "https://api.spotify.com/v1/users/" + id
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(state.getAccessToken())", forHTTPHeaderField: "Authorization")
        
        var name: String?
        
        sendRequest(request: request, postParameters: nil, method: "GET", completion: { (response) in
            let responseDict = response as? [String: AnyObject]
            name = responseDict?["display_name"] as? String
        }, isAsync: 0)
        
        if (name == nil) {
            return id
        }
        return name!
    }
    
    static func getUserSelectedPlaylists(userId: String, groupId: Int) -> [Playlist] {
        var playlists = [Playlist]()
        
        // Get users selected playlists
        let requestURL = URL(string: "http://autocollabservice.com/getuserplaylists")
        let request = NSMutableURLRequest(url: requestURL!)
        let postParameters = "&userId=" + userId + "&groupId=\(groupId)"
        
        var responsePlaylists: [[AnyObject]]?
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {
            (response) in
            let responseDict = response as? [String: [[AnyObject]]]
            responsePlaylists = responseDict?["playlists"]
        }, isAsync: 0)
        
        if (responsePlaylists == nil) {
            return []
        }
        
        for playlist in responsePlaylists! {
            let name = playlist[3] as! String
            let id = playlist[2] as! String
            playlists.append(Playlist(name: name, id: id, selected: true)!)
        }
        
        return playlists
    }
    
    static func getSongsFromPlaylist(userId: String, id: String, state: State) -> [Song] {
        
        if (id == topSongsToken) {
            return state.user.topSongs
        }
        
        let query = "https://api.spotify.com/v1/users/" + userId + "/playlists/" + id
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(state.getAccessToken())", forHTTPHeaderField: "Authorization")
        
        var items: [[String: AnyObject]]?
        
        Globals.sendRequest(request: request, postParameters: nil, method: "GET", completion: {(response) in
            //let responseDict = response as? [String: [String: AnyObject]]
            let responseDict = response as? [String: AnyObject]
            let tracks = responseDict?["tracks"] as? [String : AnyObject]
            items = tracks?["items"] as? [[String: AnyObject]]
        }, isAsync: 0)
        
        if (items == nil) {
            return []
        }
        
        var songs = [Song]()
        
        for track in items! {
            let id = track["track"]!["id"] as! String
            let name = track["track"]!["name"] as! String
            let artists = track["track"]!["artists"] as! [[String: AnyObject]]
            let artist = artists[0]["name"] as! String
            let album = track["track"]!["album"] as! [String: AnyObject]
            let pictures = album["images"] as? [[String: AnyObject]]
            let albumCover = pictures?[0]["url"] as? String
            
            
            let newSong = Song(name: name, artist: artist, id: id, imageURL: albumCover, state: state)
            songs.append(newSong!)
        }
        
        return songs
    }
    
    // MARK: Helpers
    static func getUserSongs(userId: String, groupId: Int, state: State) -> [Song]{
        
        var songs = [Song]()
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getusersongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        //creating the post parameter by concatenating the keys and values from text field
        
        let postParameters = "userId=" + userId + "&groupId=\(groupId)"
        
        var responseSongs: [[AnyObject]]?
        sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {
            (response) in
            let responseDict = response as? [String: AnyObject]
            responseSongs = responseDict?["songs"] as? [[AnyObject]]
        }, isAsync: 0)
        
        if (responseSongs == nil) {
            return []
        }
        
        for song in responseSongs! {
            let name = song[1] as! String
            let artist = song[2] as! String
            let id = song[0] as! String
            let albumCover = song[5] as? String
            let newSong = Song(name: name, artist: artist, id: id, imageURL: albumCover, state: state)
            songs.append(newSong!)
        }
        
        return songs
    }
    
    static func addUserDefaults(user: String, group: Group, state: State) {
        var songs = getUserSongs(userId: user, groupId: -1, state: state)
        addUserSongs(songs: songs, userId: user, group: group, fromPlaylist: 0)
        
        let playlists = getUserSelectedPlaylists(userId: user, groupId: -1)
        for playlist in playlists {
            let playlistSongs = getSongsFromPlaylist(userId: user, id: playlist.id, state: state)
            songs.append(contentsOf: playlistSongs)
            addUserPlaylist(playlist: playlist, userId: user, groupId: group.id)
            addUserSongs(songs: playlistSongs, userId: user, group: group, fromPlaylist: 1)
        }
        
        Globals.updateNetworkAsync(groupId: group.id, add_delete: 0, user: user, songs: songs)
    }
    
    static func createGroupRequests(userIds: [String], groupId: Int) {
        let requestURL = URL(string: "http://autocollabservice.com/creategrouprequests")
        let request = NSMutableURLRequest(url: requestURL!)
        let postParameters = "userIds=" + userIds.joined(separator: "///") + "&groupId=" + String(groupId)
        
        let _ = sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (_) in
            return
        }, isAsync: 1)
    }
    
    static func addFacebookIdToUser(fbId: String, userId: String) {
        let requestURL = URL(string: "http://autocollabservice.com/addfacebookid")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "fbId=" + fbId + "&spotifyId=" + userId
        
        let _ = Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {
            (_) in
            return
        }, isAsync: 1)
    }
    
    static func getFriends(friends: UnsafeMutablePointer<[Friend]>) {
        var responseFriends = [Friend(name: "tom", pic: nil, fbId: "1713730448694043"), Friend(name: "mike", pic: nil, fbId: "12345"), Friend(name: "john", pic: nil, fbId: "3")] as! [Friend]
        
        let params = ["fields": "id, first_name, last_name, profile_pic"]
        
        let connection = GraphRequestConnection()
        let graphrequest = GraphRequest(graphPath: "/" + AccessToken.current!.userId! +  "/friends", parameters: params, accessToken: AccessToken.current, httpMethod: .GET, apiVersion: .defaultVersion)
        
        connection.add(graphrequest) { httpResponse, result in
            switch result {
            case .success(let response):
                let data = response.dictionaryValue!["data"] as? [[String: AnyObject]]
                if (data != nil) {
                    for friend in data! {
                        let first = friend["first_name"] as! String
                        let last = friend["last_name"] as! String
                        let fbId = friend["id"] as! String
                        // Figure out how the picture is formatted
                        let pic = friend["profile_picture"] as! String
                        responseFriends.append(Friend(name: first + last, pic: pic, fbId: fbId)!)
                    }
                }
                friends.pointee = responseFriends
            case .failed(let error):
                print("Graph Request Failed: \(error)")
            }
        }
        connection.start()
    }
    
    static func logIntoFacebook(viewController: UIViewController, userId: String) {
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: [.userFriends], viewController: viewController, completion: { (loginResult) in
            switch loginResult {
            case .failed(let error):
                print(error)
            case .cancelled:
                print("User cancelled login.")
            case .success(let grantedPermissions, let declinedPermissions, let accessToken):
                self.addFacebookIdToUser(fbId: AccessToken.current!.userId!, userId: userId)
                if let networkTable = viewController as? NetworkTableViewController {
                    networkTable.userView.facebookBtn.setTitle("Disconnect Facebook Account", for: .normal)
                }
            }
        })
    }
    
    static func getFbIds(users: [String]) -> [String] {
        let requestURL = URL(string: "http://autocollabservice.com/getfbfromspotifyid")
        let request = NSMutableURLRequest(url: requestURL!)
        let postParameters = "spotifyIds=" + users.joined(separator: "///")
        
        var users = [String]()
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (response) in
            if (response != nil) {
                users = response as! [String]
            }
        }, isAsync: 0)
        
        return users
    }
    
    static func sendRequest(request: NSMutableURLRequest, postParameters: String?, method: String, completion: @escaping (AnyObject?) -> Void, isAsync: Int) {
        //setting the method to post
        request.httpMethod = method
        
        if (postParameters != nil) {
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
                completion(JSON)
                
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
    }
    
    static func getThemeColor1() -> UIColor {
        let red = 28.0
        let green = 168.0
        let blue = 0.0
        let alpha = 1.0
        return UIColor(displayP3Red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: CGFloat(alpha))
    }
    
    static func getThemeColor2() -> UIColor {
        let red = 230.0
        let green = 230.0
        let blue = 230.0
        let alpha = 1.0
        return UIColor(displayP3Red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: CGFloat(alpha))
    }
}


