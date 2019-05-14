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
import Photos
import MobileCoreServices

class Globals {
    
    //MARK: Static Properties
    static let topSongsToken = "///TOPSONGS///"
    static let defaultPic = "netDJ_5_default.png"
    static let smallOffset: CGFloat = 5
    static let medOffset: CGFloat = 15
    static let bigOffset: CGFloat = 35
    static let useFB = false
    static let dedicatedServer = false
    
    static func updateNetwork(group: Group?, state: State) {
        if group == nil {
            return
        }

        group?.increaseThreadCount()
        if let numThreads = group?.numLoadThreads {
            print (numThreads)
            if numThreads > 2 {
                group?.decreaseThreadCount()
                return
            }
        }
        
        group?.totalSongsFinishedLoading = false
        print("Group Loading")
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 20.0) {
            
            if let totalSongsFinishedLoading = group?.totalSongsFinishedLoading, !totalSongsFinishedLoading {
                if group?.numLoadThreads ?? 0 <= 1 {
                    group?.totalSongsFinishedLoading = true
                    print("timed out")
                }
                group?.decreaseThreadCount()
            }
        }
        
        if let id = group?.id {
            if id == -1 {
                return
            }
            
            let requestURL = URL(string: "http://autocollabservice.com/cgi-bin/UpdateNetwork.cgi?" + String(id) + "&" + state.getAccessToken() + "&" + randomString(length: 5))
            let request = NSMutableURLRequest(url: requestURL!)
            sendRequest(request: request, postParameters: nil, method: "GET", completion: { (response) in
                print("GOT RESPONSE")
                let responseDict = response as? [String: AnyObject]
                if group == nil {
                    return
                }
                if (responseDict == nil) {
                    group?.network = [[Int]]()
                    group?.totalSongs = [Song]()
                    print("Update Playlist Failed")
                    return
                }
                group?.network = responseDict!["network"] as! [[Int]]
                
                let songs = responseDict!["songs"] as! [[AnyObject]]
                var totalSongs = [Song]()
                var unordered = [(Song, Int)]()
                for song in songs {
                    let id = song[0] as? String ?? ""
                    let name = song[1] as? String ?? ""
                    let artist = song[2] as? String ?? ""
                    let imageURL = song[3] as? String ?? ""
                    let order = song[4] as? Int ?? -2
                    
                    let song = Song(name: name, artist: artist, id: id, imageURL: imageURL, state: state, loadNow: false)
                    unordered.append((song!, order))
                    
                    totalSongs = unordered.sorted(by: { $0.1 < $1.1 }).map { $0.0 }
                }
                
                if let cancelLoad = group?.cancelLoad, !cancelLoad {
                    group?.totalSongs = totalSongs
                    
                    if let group = group {
                        for song in group.songsPlayed {
                            if let indx = HITS.getSongIndex(song: song, songs: group.totalSongs) {
                                group.network = HITS.decreaseSongLikelihood(graph: group.network, song: indx)
                            }
                        }
                    }
                }
                
                if group?.numLoadThreads ?? 0 <= 1 {
                    group?.totalSongsFinishedLoading = true
                    print("Group Done")
                    group?.cancelLoad = false
                    if let totalSongsVC = state.totalSongsVC {
                        totalSongsVC.totalSongsDidFinishLoading()
                    }
                }
                group?.decreaseThreadCount()
            }, isAsync: 0)
        }
    }
    
    static func generateSongs(group: Group?, numSongs: Int, lastSong: Song?, state: State, viewPlaylistVC: ViewPlaylistViewController?) {
        var start: Song!
        var songs = [Song]()
        var n = numSongs
        
        group?.isGenerating = true
        
        let totalSongs = group?.totalSongs ?? [Song]()
        let network = group?.network ?? [[Int]]()
        
        if (group?.totalSongs.count == 0) {
            group?.songs = [Song]()
            group?.isGenerating = false
            viewPlaylistVC?.finishedGenerating()
            return
        }
        
        if (lastSong == nil) {
            start = HITS.getRandSong(songs: totalSongs, dist: [Int](repeating: 1, count: totalSongs.count)).copy() as! Song
            start.loadPic()
            songs.append(start)
            n -= 1

        } else {
            start = lastSong!
        }
        
        let newSongs = HITS.getNextSongs(network: network, start: start, songs: totalSongs, n: n)
        
        songs.append(contentsOf: newSongs)
        
        group?.songs?.append(contentsOf: songs)
        group?.isGenerating = false
        viewPlaylistVC?.finishedGenerating()
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
    
    static func createUser(userId: String) {
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/createuser")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "spotifyId=" + userId
        
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
        
        print(postParameters)
        
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
    
    static func getUserGroups(userId: String) -> [Int] {
        print("usergroups")
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getusergroups")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        let postParameters = "userId=" + userId
        
        var responseDict: [String: AnyObject]?
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {(response) in
            responseDict = response as? [String: AnyObject]
        }, isAsync: 0)
        
        if (responseDict == nil) {
            return []
        }
        
        return responseDict!["groups"] as! [Int]
    }
    
    static func getGroupsById(ids: [Int], state: State) -> [Group] {
        
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
            let name = group["name"] as? String ?? ""
            let admin = group["admin"] as? String ?? ""
            let id = group["id"] as? Int ?? -2
            let inviteKey = group["invite_key"] as? String ?? ""
            let picURL = group["pic"] as? String
            
            let newGroup = Group(name: name, admin: admin, id: id, picURL: picURL, inviteKey: inviteKey, state: state)
            groups.append(newGroup!)
        }
        
        return groups
    }
    
    static func setGroupName(name: String?, groupId: Int) {
        var setName = ""
        if (name == "" || name == nil) {
            setName = "///NULL///"
        } else {
            setName = name!
        }
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/addgroupname")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(groupId)" + "&name=" + setName
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {_ in}, isAsync: 1)
    }
    
    static func getUserPic(userId: String) -> String? {
        print("usergroups")
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getuserpic")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        let postParameters = "spotifyId=" + userId
        
        var picURL: String?
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {(response) in
            let responseDict = response as? [String]
            if (responseDict != nil) {
                picURL = responseDict![0]
            }
        }, isAsync: 0)
        
        return picURL
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
    
    static func isSongSaved(id: String, state: State, completion: @escaping (AnyObject?) -> Void) {
        let query = "https://api.spotify.com/v1/me/tracks/contains?ids=" + id
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(state.getAccessToken())", forHTTPHeaderField: "Authorization")
        
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
    
    static func getPlaylistSongs(userId: String, groupId: Int, state: State) -> [Song] {
        NSLog("PlaylistSong")
        var playlistSongsUnordered = [(Song, Int)]()
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getplaylistsongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(groupId)&userId=" + userId
        
        var responseDict: [String: AnyObject]?
        
        var timedOut = true
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (response) in
            responseDict = response as? [String: AnyObject]
            timedOut = false
        }, isAsync: 0)
        
        if timedOut {
            state.viewPlaylistVC?.didTimeOut = true
            return [Song]()
        }
        
        if (responseDict == nil) {
            return [Song]()
        }
        
        let songs = responseDict!["songs"] as! [[AnyObject]]
        
        for song in songs {
            let name = song[1] as! String
            let artist = song[2] as! String
            let id = song[3] as! String
            let order = song[4] as! Int
            let albumCover = song[5] as? String
            let song = Song(name: name, artist: artist, id: id, imageURL: albumCover, state: state, loadNow: true)
            song?.imageURL = albumCover
            playlistSongsUnordered.append((song!, order))
        }
        
        let playlistSongsOrdered = playlistSongsUnordered.sorted(by: { $0.1 < $1.1 })
        
        var playlistSongs = [Song]()
        
        for (song, _) in playlistSongsOrdered {
            playlistSongs.append(song)
        }
        
        return playlistSongs
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
            let id = track["id"] as? String ?? ""
            let name = track["name"] as? String ?? ""
            var artists = ""
            let artistsDict = track["artists"] as? [[String: AnyObject]] ?? []
            for artist in artistsDict {
                artists += (artist["name"] as? String ?? "")
                artists += ", "
            }
            if artistsDict.count > 0 {
                artists.removeLast(2)
            }
            let album = track["album"] as? [String: AnyObject] ?? [String: AnyObject]()
            let pictures = album["images"] as? [[String: AnyObject]]
            let albumCover = pictures?[0]["url"] as? String
            
            let newSong = Song(name: name, artist: artists, id: id, imageURL: albumCover, state: state, loadNow: false)
            additionalTracks.append(newSong!)
        }
        return additionalTracks
    }
    
    static func addUserSongs(songs: [Song], userId: String, groupId: Int, fromPlaylist: Int) {
        
        var songsCopy = [Song]()
        for song in songs {
            songsCopy.append(song.copy() as! Song)
        }
        
        var songIds = ""
        var songNames = ""
        var songArtists = ""
        var albumCovers = ""
        
        for song in songsCopy {
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
        var postParameters = "groupId=\(groupId)" + "&userId=" + userId
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
    
    static func getUserPlaylists(userId: String, state: State) -> [Playlist]? {
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
            print("Could not retrieve playlists")
            print("UserID: " + userId)
            return nil
        }

        for playlist in responsePlaylists! {
            let id = playlist["id"] as! String
            let name = playlist["name"] as! String
            let pictures = playlist["images"] as? [[String: AnyObject]]
            let albumCover = pictures?[0]["url"] as? String
            
            var newPlaylist: Playlist?
            newPlaylist = Playlist(name: name, id: id, selected: false, userId: userId, imageURL: albumCover, state: state)
            playlists.append(newPlaylist!)
        }
        
        return playlists
    }
    
    static func updatePlaylist(group: Group?, playlists: [Playlist], startingPlaylists: [String], state: State) {
        var songs = [Song]()
        DispatchQueue.main.async {
            state.viewPlaylistVC?.networkView.refreshBtn.isEnabled = false
        }
        
        var changesMade = false

        for playlist in playlists {
            // Remove playlist
            if (startingPlaylists.contains(playlist.id) && !playlist.selected) {
                changesMade = true
                group?.totalSongsFinishedLoading = false
                songs = playlist.getSongs()
                if let id = group?.id {
                    Globals.deleteUserSongs(songs: songs, userId: state.user.id, groupId: id)
                    Globals.deleteUserPlaylist(id: playlist.id, userId: state.user.id, groupId: id)
                }
            }
                // Add Playlist
            else if (!startingPlaylists.contains(playlist.id) && playlist.selected) {
                changesMade = true
                group?.totalSongsFinishedLoading = false
                songs = playlist.getSongs()
                
                if let id = group?.id {
                    Globals.addUserSongs(songs: songs, userId: state.user.id, groupId: id, fromPlaylist: 1)
                    Globals.addUserPlaylist(playlist: playlist, userId: state.user.id, groupId: id)
                }
            }
        }
        
        sleep(2)
        if group != nil && changesMade == true {
            Globals.updateNetwork(group: group, state: state)
        }
        
        DispatchQueue.main.async {
            state.viewPlaylistVC?.networkView.refreshBtn.isEnabled = true
        }
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
        let postParameters = "groupId=\(group.id!)"
        
        //adding the parameters to request body
        request.httpBody = postParameters.data(using: String.Encoding.utf8)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { _ in }, isAsync: 0)
    }
    
    static func setDisplayName(id: String, name: String) {
        let query = "http://autocollabservice.com/adddisplayname"
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        let postParameters = "spotifyId=" + id + "&displayName=" + name
        
        sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (_) in
        }, isAsync: 1)
    }
    
    static func addPhoneNumber(id: String, number: String) {
        let query = "http://autocollabservice.com/addphonenumber"
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        let postParameters = "userId=" + id + "&phoneNumber=" + number
        
        sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (_) in
        }, isAsync: 1)
    }
    
    static func getUsersName(id: String, state: State) -> String? {
        var name: String?
        
        var query = "http://autocollabservice.com/getdisplayname"
        var url = URL(string: query)
        var request = NSMutableURLRequest(url: url!)
        let postParameters = "spotifyIds=" + id
        
        sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (response) in
            if let response = response as? [String] {
                name = response.first
            }
        }, isAsync: 0)
        
        if (name != nil) {
            return name
        }
        
        query = "https://api.spotify.com/v1/users/" + id
        url = URL(string: query)
        if url != nil {
            request = NSMutableURLRequest(url: url!)
            request.setValue("Bearer \(state.getAccessToken())", forHTTPHeaderField: "Authorization")
            
            sendRequest(request: request, postParameters: nil, method: "GET", completion: { (response) in
                let responseDict = response as? [String: AnyObject]
                name = responseDict?["display_name"] as? String
            }, isAsync: 0)
        }
        
        return name
    }
    
    static func getUserSelectedPlaylists(user: User, groupId: Int, state: State) {
        var playlists = [String]()
        
        // Get users selected playlists
        let requestURL = URL(string: "http://autocollabservice.com/getuserplaylists")
        let request = NSMutableURLRequest(url: requestURL!)
        let postParameters = "&userId=" + user.id + "&groupId=\(groupId)"
        
        var responsePlaylists: [[AnyObject]]?
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {
            (response) in
            let responseDict = response as? [String: [[AnyObject]]]
            responsePlaylists = responseDict?["playlists"]
        }, isAsync: 0)
        
        if (responsePlaylists == nil) {
            print ("Failed To Get Playlists!")
            user.selectedPlaylists[groupId] = ["ERROR"]
            if let userPlaylistVC = state.userPlaylistVC {
                userPlaylistVC.selectedPlaylistsDidLoad()
            }
            return
        }
        
        for playlist in responsePlaylists! {
            let id = playlist[2] as! String
            playlists.append(id)
        }
        
        user.selectedPlaylists[groupId] = playlists
        
        if let userPlaylistVC = state.userPlaylistVC {
            userPlaylistVC.selectedPlaylistsDidLoad()
        }
    }
    
    static func getSongsFromPlaylist(userId: String, id: String, state: State) -> [Song] {
        let query = "https://api.spotify.com/v1/users/" + userId + "/playlists/" + id
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(state.getAccessToken())", forHTTPHeaderField: "Authorization")
        
        var items: [[String: AnyObject]]?
        Globals.sendRequest(request: request, postParameters: nil, method: "GET", completion: {(response) in
            let responseDict = response as? [String: AnyObject]
            
            let tracks = responseDict?["tracks"] as? [String : AnyObject]
            items = tracks?["items"] as? [[String: AnyObject]]
        }, isAsync: 0)
        
        if (items == nil) {
            return []
        }
        
        var songs = [Song]()
        
        for track in items! {
            let id = track["track"]!["id"] as? String ?? ""
            let name = track["track"]!["name"] as? String ?? ""
            let artistsDict = track["track"]!["artists"] as? [[String: AnyObject]] ?? []
            var artists = ""
            for artist in artistsDict {
                artists += (artist["name"] as? String ?? "")
                artists += ", "
            }
            if artistsDict.count > 0 {
                artists.removeLast(2)
            }
            let album = track["track"]!["album"] as? [String: AnyObject] ?? [String: AnyObject]()
            let pictures = album["images"] as? [[String: AnyObject]]
            let albumCover = pictures?[0]["url"] as? String
            
            
            let newSong = Song(name: name, artist: artists, id: id, imageURL: albumCover, state: state, loadNow: false)
            songs.append(newSong!)
        }
        
        return songs
    }
    
    // MARK: Helpers
    static func getUserSongs(user: User, groupId: Int, state: State) {
        
        user.songsHasLoaded = false
        
        var songs = [Song]()
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getusersongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        //creating the post parameter by concatenating the keys and values from text field
        
        let postParameters = "userId=" + user.id + "&groupId=\(groupId)"
        
        var responseSongs: [[AnyObject]]?
        
        var didTimeOut = true
        sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {
            (response) in
            let responseDict = response as? [String: AnyObject]
            responseSongs = responseDict?["songs"] as? [[AnyObject]]
            didTimeOut = false
        }, isAsync: 0)
        
        if didTimeOut {
            user.songs[groupId] = nil
            return
        }
        
        for song in responseSongs! {
            let name = song[1] as! String
            let artist = song[2] as! String
            let id = song[0] as! String
            let albumCover = song[5] as? String
            let newSong = Song(name: name, artist: artist, id: id, imageURL: albumCover, state: state, loadNow: false)
            songs.append(newSong!)
        }
        
        user.songs[groupId] = songs
        
        if let totalSongsVC = state.totalSongsVC {
            totalSongsVC.totalSongsDidFinishLoading()
        }
    }
    
    static func addUserDefaults(user: User, group: Group, state: State) {
        getUserSongs(user: user, groupId: group.id, state: state)
        let songs = state.user.songs[-1] ?? [Song]()
        addUserSongs(songs: songs, userId: user.id, groupId: group.id, fromPlaylist: 0)
        user.songs[group.id] = songs
        
        getUserSelectedPlaylists(user: user, groupId: group.id, state: state)
        state.user.selectedPlaylists[group.id] = state.user.selectedPlaylists[-1]
        
        if let playlists = NSKeyedUnarchiver.unarchiveObject(withFile: Globals.playlistsFilePath) as? [Playlist] {
            for id in state.user.selectedPlaylists[group.id]! {
                var playlist: Playlist!
                
                let indx = playlists.index(where: { (item) -> Bool in
                    item.id == id
                })
                if (indx != nil) {
                    playlist = playlists[indx!]
                    playlist.state = state
                    addUserPlaylist(playlist: playlist, userId: user.id, groupId: group.id)
                    addUserSongs(songs: playlist.getSongs(), userId: user.id, groupId: group.id, fromPlaylist: 1)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            Globals.updateNetwork(group: group, state: state)
        }
    }
    
    static func createGroupRequests(userIds: [String]?, groupId: Int, inviter: String) {
        if userIds == nil {
            return
        }
        let requestURL = URL(string: "http://autocollabservice.com/creategrouprequests")
        let request = NSMutableURLRequest(url: requestURL!)
        let postParameters = "userIds=" + userIds!.joined(separator: "///") + "&groupId=" + String(groupId) + "&inviter=" + inviter
        
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
        
        var users: [String]?
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (response) in
            if (response != nil) {
                users = response as? [String]
            }
        }, isAsync: 0)
        
        if users == nil {
            return []
        } else {
            return users!
        }
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
        
        URLSession.shared.configuration.timeoutIntervalForRequest = 5.0
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if error != nil{
                print("error is \(String(describing: error))")
                return;
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 429 {
                    print("Rate Limit Exceeded")
                    if let waitTime = httpResponse.allHeaderFields["Retry-After"] as? Double {
                        DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                            sendRequest(request: request, postParameters: postParameters, method: method, completion: completion, isAsync: isAsync)
                            return
                        }
                    }
                }
            }
            
            //parsing the response
            do {
                //converting resonse to NSDictionary
                JSON  = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as AnyObject
                completion(JSON)
            } catch {
                print("Rquest: \(request.url?.absoluteString) Error: \(error)")
            }

            if (isAsync == 0) {
                semaphore.signal()
            }
        }
        //executing the
        task.resume()
        if (isAsync == 0) {
            _ = semaphore.wait(timeout: .now() + 6.0)
        }
    }
    
    static func addPhotoFromLibrary(controller: UIViewController) {
        // Get the current authorization state.
        let access = PHPhotoLibrary.authorizationStatus()
        
        switch access {
        case .authorized:
            break
        case .denied:
            return
        case .notDetermined:
            // Access has not been determined.
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                
                if (newStatus == PHAuthorizationStatus.authorized) {
                    
                }
                    
                else {
                    return
                }
            })
        case .restricted:
            return
        }
        
        // https://stackoverflow.com/questions/39812390/how-to-load-image-from-camera-or-photo-library-in-swift/39812909
        let photoLibrary = UIImagePickerController()
        let isPhotoLibraryAvailable = UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
        let isSavedPhotoAlbumAvailable = UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum)
        
        if !isPhotoLibraryAvailable && !isSavedPhotoAlbumAvailable { return }
        let type = kUTTypeImage as String
        
        if isPhotoLibraryAvailable {
            photoLibrary.sourceType = .photoLibrary
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
                if availableTypes.contains(type) {
                    photoLibrary.mediaTypes = [type]
                    photoLibrary.allowsEditing = true
                }
            }
            
            photoLibrary.sourceType = .savedPhotosAlbum
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .savedPhotosAlbum) {
                if availableTypes.contains(type) {
                    photoLibrary.mediaTypes = [type]
                }
            }
        } else {
            return
        }
        
        photoLibrary.allowsEditing = true
        photoLibrary.delegate = controller as! UIImagePickerControllerDelegate & UINavigationControllerDelegate
        DispatchQueue.main.async {
            controller.present(photoLibrary, animated: true, completion: nil)
        }
    }
    
    static func addPhotoFromCamera(controller: UIViewController) {
        let access = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        switch access {
        case .authorized:
            break
        case .denied:
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                if granted == false
                {
                    return
                }
            });
        case .restricted:
            return
        }
        
        let camera = UIImagePickerController()
        let isCameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        let isRearCameraAvailable = UIImagePickerController.isCameraDeviceAvailable(.rear)
        let isFrontCameraAvailable = UIImagePickerController.isCameraDeviceAvailable(.front)
        let sourceTypeCamera = UIImagePickerControllerSourceType.camera
        let rearCamera = UIImagePickerControllerCameraDevice.rear
        let frontCamera = UIImagePickerControllerCameraDevice.front
        
        if !isCameraAvailable { return }
        let type1 = kUTTypeImage as String
        
        if isCameraAvailable {
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .camera) {
                if availableTypes.contains(type1) {
                    camera.mediaTypes = [type1]
                    camera.sourceType = sourceTypeCamera
                }
            }
            
            if isRearCameraAvailable {
                camera.cameraDevice = rearCamera
            } else if isFrontCameraAvailable {
                camera.cameraDevice = frontCamera
            }
        } else {
            return
        }
        
        camera.allowsEditing = true
        camera.showsCameraControls = true
        camera.delegate = controller as! UIImagePickerControllerDelegate & UINavigationControllerDelegate
        DispatchQueue.main.async {
            controller.present(camera, animated: true, completion: nil)
        }
        
    }
    
    static func showAlert(text: String, view: UIView) {
        let alertView = UIView(frame: CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: 50))
        alertView.backgroundColor = Globals.getThemeColor1()
        alertView.alpha = 0
        view.addSubview(alertView)
        
        let alertLabel = UILabel(frame: CGRect(x: 0, y: 0, width: alertView.frame.width, height: alertView.frame.height))
        alertLabel.textAlignment = .center
        alertLabel.textColor = UIColor.white
        alertView.addSubview(alertLabel)
        
        alertLabel.text = text
        alertView.alpha = 1
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            alertView.frame = CGRect(x: 0, y: view.frame.height - 50, width: view.frame.width, height: 50)
        }) { (finished) in
            UIView.animate(withDuration: 0.2, delay: 0.7, options: .curveEaseOut, animations: {
                alertView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: 50)
            }) { (finished) in
                alertView.alpha = 0
            }
        }
    }
    
    static func roundAllCorners(imageView: UIImageView) {
        let path = UIBezierPath(roundedRect: imageView.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 10, height: 10))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        imageView.layer.mask = mask
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
    
    static func getThemeColor3() -> UIColor {
        let red = 150.0
        let green = 150.0
        let blue = 150.0
        let alpha = 1.0
        return UIColor(displayP3Red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: CGFloat(alpha))
    }
    
    static func deleteStorage() {
        let fileManager = FileManager()
        do {
            try fileManager.removeItem(atPath: Globals.networksFilePath)
        } catch {
            print("network file does not exist")
        }
        
        do {
            try fileManager.removeItem(atPath: Globals.playlistsFilePath)
        } catch {
            print("playlists file does not exist")
        }
        
    }
    
    static var networksFilePath: String {
        //1 - manager lets you examine contents of a files and folders in your app; creates a directory to where we are saving it
        let manager = FileManager.default
        //2 - this returns an array of urls from our documentDirectory and we take the first path
        let url = manager.urls(for: .libraryDirectory, in: .userDomainMask).first
        //3 - creates a new path component and creates a new file called "Data" which is where we will store our Data array.
        return (url!.appendingPathComponent("NetworksData").path)
    }
    
    static var playlistsFilePath: String {
        //1 - manager lets you examine contents of a files and folders in your app; creates a directory to where we are saving it
        let manager = FileManager.default
        //2 - this returns an array of urls from our documentDirectory and we take the first path
        let url = manager.urls(for: .libraryDirectory, in: .userDomainMask).first
        //3 - creates a new path component and creates a new file called "Data" which is where we will store our Data array.
        return (url!.appendingPathComponent("PlaylistsData").path)
    }
}


