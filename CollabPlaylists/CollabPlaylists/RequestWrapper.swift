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
    
    static func loadSongs(numSongs: Int, lastSong: String?, group: Group, session: SPTSession) -> [Song] {
        NSLog("LoadSongs")
        var songs = [Song]()
        // Generate Songs
        var query = ""
        for user in group.users! {
            let songIds = getSongs(userId: user, groupId: group.id)
            if (query == "") {
                query = user + ":" + songIds
            } else {
                query = query + ";" + user + ":" + songIds
            }
        }
        if (lastSong == nil) {
            query = query + "&\(group.id)&\(numSongs)&1&None"
        }
        else {
            query = query + "&\(group.id)&\(numSongs)&1&\(lastSong!)"
        }
        
        deletePlaylist(group: group)
        
        //created NSURL
        let requestURL2 = URL(string: "http://autocollabservice.com/cgi-bin/GeneratePlaylist.cgi?" + query)
        
        //creating NSMutableURLRequest
        let request2 = NSMutableURLRequest(url: requestURL2!)
        
        //setting the method to get
        request2.httpMethod = "GET"
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task2 = URLSession.shared.dataTask(with: request2 as URLRequest){
            data, response, error in
            
            do {
                
                //converting resonse to NSDictionary
                let myJSON =  try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String:AnyObject]
                
                NSLog("ids: \(myJSON)")
                
                if let parseJSON = myJSON {
                    let songIds = parseJSON["songs"] as! [String]
                    
                    if (songIds.count > 0) {
                        for id in songIds {
                            let info = self.getTrackInfo(id: id, session: session)
                            let song = Song(name: info.0, artist: info.1, id: id)
                            songs.append(song!)
                        }
                    }
                }
                semaphore.signal()
            } catch {
                NSLog("\(error)")
            }
        }
        //executing the task
        task2.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        var ordering = 0
        for song in songs {
            addPlaylistSong(song: song, ordering: ordering, group: group)
            ordering += 1
        }
        
        return songs
    }
    
    static func getSongs(userId: String, groupId: Int) -> String {
        NSLog("GetSongs")
        NSLog("\(userId)")
        NSLog("\(groupId)")
        
        var songIds = ""
        var numSongs = 0
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let requestURL = URL(string: "http://autocollabservice.com/getusersongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "userId=" + userId + "&groupId=\(groupId)&onlyAdded=0"
        
        //adding the parameters to request body
        request.httpBody = postParameters.data(using: String.Encoding.utf8)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            do {
                //converting resonse to NSDictionary
                let myJSON =  try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: AnyObject]
                
                
                //parsing the json
                if let parseJSON = myJSON {
                    let songs = parseJSON["songs"]! as! [[AnyObject]]
                    for song in songs {
                        numSongs += 1
                        let id = song[0] as! String
                        if (songIds == "") {
                            songIds = id
                        } else {
                            songIds = songIds + "," + id
                        }
                    }
                    
                    semaphore.signal()
                }
            } catch {
                NSLog("\(error)")
            }
        }
        //executing the task
        task.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        NSLog("songIds" + songIds)
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
        
        let response: AutoreleasingUnsafeMutablePointer<URLResponse?>? = nil
        
        let data = try? NSURLConnection.sendSynchronousRequest(request!, returning: response)
        
        if (data == nil) {
            return ("None","None")
        }
        
        do {
            if let track = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: AnyObject] {
                
                let name = track["name"] as! String
                let artists = track["artists"] as? [[String: AnyObject]]
                var artistName =  artists?[0]["name"] as? String
                if (artistName == nil) {
                    artistName = "Not Found"
                }
                return (name, artistName!)
            }
        } catch _ as NSError {
            NSLog("error")
        }
        return ("None","None")
    }
    
    static func deletePlaylist(group: Group) {
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/deleteplaylist")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(group.id)"
        
        //adding the parameters to request body
        request.httpBody = postParameters.data(using: String.Encoding.utf8)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            if error != nil{
                print("error is \(String(describing: error))")
                return;
            }
            semaphore.signal()
            
            NSLog("\(String(describing: data))")
        }
        //executing the task
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
    }
    
    static func addPlaylistSong(song: Song, ordering: Int, group: Group) {
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/addplaylistsong")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(group.id)&songId=" + song.id + "&songName=" + song.name + "&songArtist=" + song.artist + "&ordering=\(ordering)"
        
        //adding the parameters to request body
        request.httpBody = postParameters.data(using: String.Encoding.utf8)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            if error != nil{
                print("error is \(String(describing: error))")
                return;
            }
            
            semaphore.signal()
            
            NSLog("\(String(describing: data))")
        }
        //executing the task
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
    }
    
    static func addGroupUser(groupId: Int, userId: String) {
        
        let semaphore = DispatchSemaphore(value: 0)
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/addgroupuser")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(groupId)" + "&userId=" + userId
        
        //adding the parameters to request body
        request.httpBody = postParameters.data(using: String.Encoding.utf8)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            if error != nil{
                print("error is \(String(describing: error))")
                return;
            }
            semaphore.signal()
            
            NSLog("\(String(describing: data))")
            
        }
        //executing the task
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
    }
}
