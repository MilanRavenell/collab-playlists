//
//  ViewPlaylistViewController.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 4/10/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit
import AVFoundation

class ViewPlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SPTAudioStreamingPlaybackDelegate {
    
    //MARK: Properties
    @IBOutlet weak var unactiveLabel: UILabel!
    @IBOutlet weak var activateBtn: UIButton!
    @IBOutlet weak var songsTable: UITableView!
    var songs = [Song]()
    var state: State?
    @IBOutlet weak var playPauseBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (self.state!.player != nil) {
            self.state!.player?.playbackDelegate = self
        }

        // Do any additional setup after loading the view.
        // Do any additional setup after loading the view.
        if ((songsTable) != nil) {
            songsTable.dataSource = self
            songsTable.delegate = self
        }
        
        // FIX THIS
        if (self.state!.group!.activated == false) {
            self.songsTable.isHidden = true
            self.playPauseBtn.isHidden = true
            self.nextBtn.isHidden = true
        }
        
        if (self.state!.group!.admin != self.state!.userId) {
            self.activateBtn.isHidden = true
            self.playPauseBtn.isHidden = true
            self.nextBtn.isHidden = true
            self.songs = getPlaylistSongs()
            songsTable.reloadData()
            return
        }
        
        if(self.state!.group!.activated == true) {
            self.songs = getPlaylistSongs()
        }
        
        if (self.state!.group!.admin == self.state!.userId && self.state!.group!.activated == false) {
            self.activateBtn.setTitle("Activate", for: .normal)
        }

        if (self.state!.group!.admin == self.state!.userId && self.state!.group!.activated == true) {
            self.activateBtn.setTitle("Deactivate", for: .normal)
        }

        // Check playback state
        if (self.state!.player!.playbackState != nil && self.state!.player!.playbackState.isPlaying) {
            playPauseBtn.setTitle("Pause", for: .normal)
        }
        else {
            playPauseBtn.setTitle("Play", for: .normal)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Table Functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "PlaylistSongTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? PlaylistSongTableViewCell else{
            fatalError("It messed up")
        }
        
        // Fetches the appropriate song
        let song = songs[indexPath.row]
        
        cell.name.text = song.name
        cell.artist.text = song.artist
        
        if (indexPath.section == 0 && indexPath.row == 0) {
            cell.name.textColor = UIColor.blue
            cell.artist.textColor = UIColor.blue
        } else {
            cell.name.textColor = UIColor.black
            cell.artist.textColor = UIColor.black
        }
        
        // Configure the cell...
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (self.state!.userId == self.state!.group!.admin) {
            songs.removeFirst(indexPath.row)
            playPauseBtn.setTitle("Pause", for: .normal)
            playSong(id: songs[0].id)
            
            self.state?.hasSong = true
            let newSongs = RequestWrapper.loadSongs(numSongs: indexPath.row, lastSong: songs.last?.id, group: self.state!.group!, session: self.state!.session, reuseNetwork: 1)
            for song in newSongs {
                self.songs.append(song)
            }
            updatePlaylistSongs()
            self.songsTable.reloadData()
        }
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "playlistBackSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! GroupViewController
            destinationVC.state = state
        }
        if (segue.identifier == "mySongSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! SongTableViewController
            destinationVC.state = state
        }
    }
    
    
    //MARK: Actions
    
    @IBAction func activateBtnPressed(_ sender: Any) {
        if (activateBtn.titleLabel?.text == "Activate") {
            
            //created NSURL
            let requestURL = URL(string: "http://autocollabservice.com/activategroup")
            
            //creating NSMutableURLRequest
            let request = NSMutableURLRequest(url: requestURL!)
            
            //creating the post parameter by concatenating the keys and values from text field
            let postParameters = "groupId=\(self.state!.group!.id)"
            
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
                
                NSLog("\(String(describing: data))")
            }
            //executing the task
            task.resume()
            
            activateBtn.setTitle("Deactivate", for: .normal)
            songsTable.isHidden = false
            self.state!.group?.activated = true
            self.playPauseBtn.isHidden = false
            self.playPauseBtn.setTitle("Play", for: .normal)
            self.nextBtn.isHidden = false
            
            self.songs = RequestWrapper.loadSongs(numSongs: 10, lastSong: nil, group: self.state!.group!, session: self.state!.session, reuseNetwork: 0)
            updatePlaylistSongs()
            self.songsTable.reloadData()
        }
        
        if (activateBtn.titleLabel?.text == "Deactivate") {
            //created NSURL
            let requestURL = URL(string: "http://autocollabservice.com/deactivategroup")
            
            //creating NSMutableURLRequest
            let request = NSMutableURLRequest(url: requestURL!)
            
            //creating the post parameter by concatenating the keys and values from text field
            let postParameters = "groupId=\(self.state!.group!.id)"
            
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
                
                NSLog("\(String(describing: data))")
            }
            //executing the task
            task.resume()
            
            self.state!.player?.setIsPlaying(false, callback: { (error) in
                if (error != nil) {
                    print("error")
                }
            })
            
            activateBtn.setTitle("Activate", for: .normal)
            songsTable.isHidden = true
            self.state!.group?.activated = false
            self.playPauseBtn.isHidden = true
            self.nextBtn.isHidden = true
            self.state?.hasSong = false
            songs = []
        }
    }
    
    @IBAction func playPauseBtnPressed(_ sender: Any) {
        if (self.state!.player!.playbackState != nil && self.state!.hasSong == true) {
            if (self.state!.player!.playbackState.isPlaying) {
                self.state!.player?.setIsPlaying(false, callback: { (error) in
                    if (error != nil) {
                        print("error")
                    }
                })
                playPauseBtn.setTitle("Play", for: .normal)
            }
            else {
                self.state!.player?.setIsPlaying(true, callback: { (error) in
                    if (error != nil) {
                        print("error")
                    }
                })
                playPauseBtn.setTitle("Pause", for: .normal)
            }
        } else {
            playSong(id: songs[0].id)
            playPauseBtn.setTitle("Pause", for: .normal)
            self.state?.hasSong = true
        }
    }
    
    @IBAction func nextBtnPressed(_ sender: Any) {
        songs.removeFirst()
        playSong(id: songs[0].id)
        let newSongs = RequestWrapper.loadSongs(numSongs: 1, lastSong: songs.last?.id, group: self.state!.group!, session: self.state!.session, reuseNetwork: 1)
        for song in newSongs {
            self.songs.append(song)
        }
        self.state?.hasSong = true
        updatePlaylistSongs()
        self.songsTable.reloadData()
    }
    
    // MARK: SPTAudioStreamingPlaybackDelegate Methods
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        if isPlaying {
            self.activateAudioSession()
        } else {
            self.deactivateAudioSession()
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: String!) {
        songs.removeFirst()
        self.songs = RequestWrapper.loadSongs(numSongs: 1, lastSong: songs.last?.id, group: self.state!.group!, session: self.state!.session, reuseNetwork: 1)
        self.songsTable.reloadData()
        playSong(id: songs[0].id)
    }
    
    // MARK: Helpers
    
    func playSong(id: String) {
        self.state!.player?.playSpotifyURI("spotify:track:\(id)", startingWith: 0, startingWithPosition: 0, callback: { (error) in
            if (error == nil) {
                print("playing!")
            }
        })
        //Change cell color
        //updatePlayingSongColor()
    }
    
    
    func getAdditionalTracks(userId: String, num: Int) -> [String] {
        NSLog("AdditionalTracks")
        var additionalTracks = [String]()
        let query = "https://api.spotify.com/v1/me/top/tracks?limit=\(num)"
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)

        request.setValue("Bearer \(self.state!.session.accessToken!)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            do {
                
                //converting resonse to NSDictionary
                let myJSON =  try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String:AnyObject]
                
                if let parseJSON = myJSON {
                    let tracks = parseJSON["items"] as! [[String: AnyObject]]
                    for track in tracks {
                        let id = track["id"] as! String
                        additionalTracks.append(id)
                    }
                }
                semaphore.signal()
            } catch {
                NSLog("\(error)")
            }
            
            NSLog("\(String(describing: data))")
        }
        //executing the task
        task.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        return additionalTracks
    }
    
    func getPlaylistSongs() -> [Song] {
        NSLog("PlaylistSong")
        var playlistSongsUnordered = [(Song, Int)]()
        
        let semaphore = DispatchSemaphore(value: 0)
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getplaylistsongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(self.state!.group!.id)"
        //adding the parameters to request body
        request.httpBody = postParameters.data(using: String.Encoding.utf8)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            do {
                
                //converting resonse to NSDictionary
                let myJSON =  try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String:AnyObject]
                
                if let parseJSON = myJSON {
                    let songs = parseJSON["songs"] as! [[AnyObject]]
                    
                    for song in songs {
                        let name = song[1] as! String
                        let artist = song[2] as! String
                        let id = song[3] as! String
                        let order = song[4] as! Int
                        let song = Song(name: name, artist: artist, id: id)
                        playlistSongsUnordered.append((song!, order))
                    }
                }
                semaphore.signal()
            } catch {
                NSLog("\(error)")
            }
        }
        //executing the task
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        
        let playlistSongsOrdered = playlistSongsUnordered.sorted(by: { $0.1 < $1.1 })
        
        var playlistSongs = [Song]()
        
        for (song, _) in playlistSongsOrdered {
            playlistSongs.append(song)
        }
        
        return playlistSongs
    }
    
    func activateAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // MARK: Deactivate audio session
    
    func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    func updatePlaylistSongs() {
        RequestWrapper.deletePlaylist(group: self.state!.group!)
        RequestWrapper.addPlaylistSongs(songs: self.songs, group: self.state!.group!)
    }
}
