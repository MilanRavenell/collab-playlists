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
    var selectedSongs: Song?
    var session: SPTSession!
    var player: SPTAudioStreamingController?
    var searchController: UISearchController?
    var userId: String?
    var group: Group?
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NSLog("\(self.group)")
        
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
            searchController?.hidesNavigationBarDuringPresentation = false
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
        
        let semaphore = DispatchSemaphore(value: 0)
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/addusersong")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        //getting values from text fields
        let songId = selectedSongs?.id
        let songName = selectedSongs?.name
        let songArtist = selectedSongs?.artist
        
        //creating the post parameter by concatenating the keys and values from text field
        var postParameters = "userId=" + self.userId! + "&songId=" + songId!
        postParameters = postParameters + "&songName=" + songName! + "&songArtist=" + songArtist! + "&groupId=\(self.group!.id)&isTop=0"
        
        //adding the parameters to request body
        request.httpBody = postParameters.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            semaphore.signal()
            if error != nil{
                print("error is \(String(describing: error))")
                return;
            }            
        }
        //executing the task
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        RequestWrapper.loadSongs(numSongs: 10, lastSong: nil, group: self.group!, session: self.session)
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
        
        NSLog("\(session)")
        
        let request = try? SPTSearch.createRequestForSearch(withQuery: query, queryType: SPTSearchQueryType.queryTypeTrack, accessToken: session.accessToken)
        
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
            destinationVC.session = session
            destinationVC.userId = userId
            destinationVC.group = group
            destinationVC.player = player!
        }
    }
    

}
