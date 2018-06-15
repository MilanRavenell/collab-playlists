//
//  SongSearchViewController.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 3/19/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class SongSearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {
    
    //MARK: Properties
    @IBOutlet weak var songSearchBar: UISearchBar!
    @IBOutlet weak var songTable: UITableView!
    var songs = [Song]()
    var state: State?
    var selectedSongs: Song?
    var searchController: UISearchController?
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NSLog("\(self.state!.group)")
        
        if ((songTable) != nil) {
            songTable.dataSource = self
            songTable.delegate = self
        }
        
        searchController = UISearchController(searchResultsController: nil)
        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            searchController?.searchResultsUpdater = self
            searchController?.obscuresBackgroundDuringPresentation = false
            searchController?.searchBar.placeholder = "Search Songs"
            searchController?.hidesNavigationBarDuringPresentation = true
        } else {
            searchController?.hidesNavigationBarDuringPresentation = false
            searchController?.dimsBackgroundDuringPresentation = false
            self.definesPresentationContext = true
            searchController?.searchResultsUpdater = self
            searchController?.searchBar.sizeToFit()
            self.songTable.tableHeaderView = searchController?.searchBar
        }
        definesPresentationContext = true
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
        let cellIdentifier = "SongSearchTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? SongSearchTableViewCell else{
            fatalError("It messed up")
        }
        
        // Fetches the appropriate song
        let song = self.songs[indexPath.row]
        
        cell.songName.text = song.name
        cell.songArtist.text = song.artist
        
        // Configure the cell...
        
        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedSongs = songs[indexPath.row]
        
        //getting values from text fields
        let song = Song(name: selectedSongs!.name, artist: selectedSongs!.artist, id: selectedSongs!.id)
        
        RequestWrapper.addUserSongs(songs: [song!], userId: self.state!.userId, groupId: self.state!.group!.id, isTop: 0)
        
        if self.state!.group!.activated == true {
            RequestWrapper.loadSongs(numSongs: 10, lastSong: nil, group: self.state!.group!, session: self.state!.session)
        }
        
        performSegue(withIdentifier: "songSelectSegue", sender: self)
    }
    
    
    //MARK: Search Bar Functions
    
    func updateSearchResults(for searchController: UISearchController) {
        
        if (searchController.searchBar.text! != "") {
            NSLog("updateSearchResults")
            
            self.songs = getSongs(query: searchController.searchBar.text!)
            
            for song in self.songs {
                NSLog("\(song.name); \(song.artist)")
                
            }
            
            self.songTable.reloadData()
        }
        
    }
    
    // MARK: Spotify Search Functions
    func getSongs(query: String) -> [Song] {
        
        NSLog("getSongs")
        
        songs = [Song]()
        
        NSLog("\(self.state!.session)")
        
        let request = try? SPTSearch.createRequestForSearch(withQuery: query, queryType: SPTSearchQueryType.queryTypeTrack, accessToken: self.state!.session.accessToken)
        
        if (request == nil) {
            NSLog("failed")
            return songs
        }
        
        NSLog("1")
        
        let response: AutoreleasingUnsafeMutablePointer<URLResponse?>? = nil
        
        let data = try? NSURLConnection.sendSynchronousRequest(request!, returning: response)
        
        NSLog("2")
        
        if (data == nil) {
            return songs
        }

        do {
            if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: AnyObject] {
                NSLog("3")
                if let tracks = jsonResult["tracks"]?["items"] as? [[String: AnyObject]] {
                    for track in tracks {
                        NSLog("4")
                        let name = track["name"] as! String
                        let id = track["id"] as! String
                        let artists = track["artists"] as? [[String: AnyObject]]
                        var artistName =  artists?[0]["name"] as? String
                        if (artistName == nil) {
                            artistName = "Not Found"
                        }
                        let song = Song(name: name, artist: artistName!, id: id)
                        songs.append(song!)
                    }
                }
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return songs
    }
    
    // MARK: Action
    
    @IBAction func backBtnPressed(_ sender: Any) {
        performSegue(withIdentifier: "songSelectSegue", sender: self)
        NSLog("back")
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "songSelectSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! SongTableViewController
            destinationVC.state = state
        }
        if (segue.identifier == "userPlaylistsSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! UserPlaylistsTableViewController
            destinationVC.state = state
        }
        
    }
    

}
