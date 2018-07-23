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
    @IBOutlet weak var songTable: UITableView!
    var songs = [Song]()
    var state: State?
    var selectedSong: Song?
    var searchController: UISearchController?
    var prevController: String?
    

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Add Songs"
        // Do any additional setup after loading the view.
        NSLog("\(self.state!.group)")
        
        if ((songTable) != nil) {
            songTable.dataSource = self
            songTable.delegate = self
            songTable.frame = self.view.frame
            songTable.backgroundColor = Globals.getThemeColor2()
            songTable.tableFooterView = UIView()
        }
        
        searchController = UISearchController(searchResultsController: nil)
        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            searchController?.searchResultsUpdater = self
            searchController?.obscuresBackgroundDuringPresentation = false
            searchController?.searchBar.placeholder = "Search Songs"
            searchController?.hidesNavigationBarDuringPresentation = true
            searchController?.searchBar.tintColor = UIColor.white
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        } else {
            searchController?.hidesNavigationBarDuringPresentation = false
            searchController?.dimsBackgroundDuringPresentation = false
            self.definesPresentationContext = true
            searchController?.searchResultsUpdater = self
            searchController?.searchBar.sizeToFit()
            self.songTable.tableHeaderView = searchController?.searchBar
        }
        definesPresentationContext = true
        
        navigationController?.navigationBar.barTintColor = Globals.getThemeColor1()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        rightSwipeGesture.direction = .right
        self.songTable.addGestureRecognizer(rightSwipeGesture)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.searchController?.searchBar.becomeFirstResponder()
        }
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
        
        cell.backgroundColor = UIColor.clear
        
        let albumCover = UIImageView(frame: CGRect(x: 0, y: 0, width: 80, height: cell.frame.height))
        cell.addSubview(albumCover)
        
        // Fetches the appropriate song
        let song = self.songs[indexPath.row]
        albumCover.image = song.image
        if (song.imageURL != nil) {
            let url = URL(string: song.imageURL!)
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url!) {
                    DispatchQueue.main.async {
                        albumCover.image = UIImage(data: data)
                    }
                }
            }
        }
        
        cell.songName.text = song.name
        cell.songArtist.text = song.artist
        cell.songArtist.font = cell.songArtist.font.withSize(15)
        
        // Configure the cell...
        
        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedSong = songs[indexPath.row]
        
        Globals.addUserSongs(songs: [selectedSong!], userId: self.state!.user.id, group: self.state!.group!, fromPlaylist: 0)
        self.state!.user.songs[self.state!.group!.id]!.append(selectedSong!)
        if (self.state!.group?.id != -1) {
            self.state!.group?.totalSongs.append(selectedSong!)
        }
        
        if (self.state!.group!.id != -1) {
            Globals.updateNetworkAsync(groupId: self.state!.group!.id, add_delete: 0, user: self.state!.user.id, songs: [selectedSong!])
        }
        
        performSegue(withIdentifier: "songSelectSegue", sender: self)
    }
    
    
    //MARK: Search Bar Functions
    
    func updateSearchResults(for searchController: UISearchController) {
        
        if (searchController.searchBar.text! != "") {
            NSLog("updateSearchResults")
            
            getSongs(query: searchController.searchBar.text!)
        }
        
    }
    
    // MARK: Spotify Search Functions
    func getSongs(query: String) {
        var songs = [Song]()
        
        let request = try? SPTSearch.createRequestForSearch(withQuery: query, queryType: SPTSearchQueryType.queryTypeTrack, accessToken: self.state!.getAccessToken())
        
        var JSON: [String: [String: AnyObject]]?
        
        let task = URLSession.shared.dataTask(with: request as! URLRequest) {
            data, response, error in
            
            if error != nil{
                print("error is \(String(describing: error))")
                return;
            }
            
            //parsing the response
            do {
                //converting resonse to NSDictionary
                JSON  = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: [String: AnyObject]]
                if let tracks = JSON?["tracks"]?["items"] as? [[String: AnyObject]] {
                    for track in tracks {
                        let name = track["name"] as! String
                        let id = track["id"] as! String
                        let artists = track["artists"] as? [[String: AnyObject]]
                        var artistName =  artists?[0]["name"] as? String
                        if (artistName == nil) {
                            artistName = "Not Found"
                        }
                        let album = track["album"] as! [String: AnyObject]
                        let pictures = album["images"] as? [[String: AnyObject]]
                        let albumCover = pictures?[0]["url"] as? String
                        let song = Song(name: name, artist: artistName!, id: id, imageURL: albumCover, state: self.state!)
                        songs.append(song!)
                    }
                    self.songs = songs
                    DispatchQueue.main.async {
                        self.songTable.reloadData()
                    }
                }
            } catch {
                print("\(error)")
            }
        }
        //executing the
        task.resume()
    }
    
    func didSwipeRight() {
        self.performSegue(withIdentifier: "songSelectSegue", sender: self)
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
            let destinationVC = navVC.viewControllers.first as! SongsViewController
            destinationVC.state = state
            destinationVC.prevController = prevController
        }
    }
    

}
