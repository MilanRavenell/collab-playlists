//
//  TotalSongsViewController.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/17/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit
import MediaPlayer

class TotalSongsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {

    // MARK: Properties
    @IBOutlet weak var songTable: UITableView!
    var searchController: UISearchController?
    var songs = [Song]()
    var state: State?
    var activityIndicator: UIActivityIndicatorView?
    var selectedSong: Song?
    var viewPlaylistView: ViewPlaylistViewController?
    @IBOutlet weak var backBtn: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if ((songTable) != nil) {
            songTable.dataSource = self
            songTable.delegate = self
            songTable.frame = self.view.frame
            songTable.backgroundColor = Globals.getThemeColor2()
            songTable.tableFooterView = UIView()
            songTable.rowHeight = 90
        }
        
        if (self.state!.group!.totalSongsFinishedLoading) {
            for song in self.state!.group!.totalSongs {
                
                let indx = songs.index(where: { (item) -> Bool in
                    item.id == song.id
                })
                if (indx == nil) {
                    songs.append(song)
                }
                
            }
        } else {
            activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            activityIndicator?.center = self.view.center
            activityIndicator?.startAnimating()
            self.view.addSubview(activityIndicator!)
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
        
        navigationController?.navigationBar.barTintColor = Globals.getThemeColor1()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        rightSwipeGesture.direction = .right
        self.songTable.addGestureRecognizer(rightSwipeGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        while (!self.state!.group!.totalSongsFinishedLoading) {
            let _ = DispatchSemaphore(value: 0).wait(timeout: .init(uptimeNanoseconds: 3))
        }
        for song in self.state!.group!.totalSongs {
            
            let indx = songs.index(where: { (item) -> Bool in
                item.id == song.id
            })
            if (indx == nil) {
                songs.append(song)
            }
        }
        self.songTable.reloadData()
        self.activityIndicator?.stopAnimating()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "TotalSongsTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TotalSongsTableViewCell else{
            fatalError("It messed up")
        }
        
        cell.backgroundColor = UIColor.clear
        
        let albumCover = UIImageView(frame: CGRect(x: 0, y: 0, width: 80, height: cell.frame.height))
        cell.addSubview(albumCover)
        
        // Fetches the appropriate song
        let song = self.songs[indexPath.row]
        if (song.imageURL == nil) {
            albumCover.image = UIImage(named: Globals.defaultPic)
        } else {
            albumCover.image = song.image
        }
        
        cell.name.text = song.name
        cell.name.frame = CGRect(x: cell.name.frame.minX, y: cell.name.frame.minY, width: cell.frame.width - cell.name.frame.minX, height: cell.name.frame.height)
        
        cell.artist.text = song.artist
        
        cell.artist.frame = CGRect(x: cell.artist.frame.minX, y: cell.artist.frame.minY, width: cell.frame.width - cell.artist.frame.minX, height: cell.artist.frame.height)
        
        cell.artist.font = cell.artist.font.withSize(15)
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedSong = self.songs[indexPath.row]
        
        let alert = UIAlertController(title: selectedSong?.name, message: "", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Play Now", style: .default, handler: playNow))
        alert.addAction(UIAlertAction(title: "Add to Queue", style: .default, handler: addToQueue))
        
        if (!selectedSong!.saved) {
            alert.addAction(UIAlertAction(title: "Save To Library", style: .default, handler: saveSong))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil))
        
        if (self.searchController!.isActive) {
            self.searchController!.present(alert, animated: true)
        } else {
            self.present(alert, animated: true)
        }
        self.songTable.deselectRow(at: indexPath, animated: true)
    }
    
    func playNow(alert: UIAlertAction!) {
        self.viewPlaylistView?.playSong(player: self.state!.player!, song: selectedSong!)
        self.state!.group?.songs = [self.selectedSong!]
        let nextSongs = Globals.generateSongs(groupId: self.state!.group!.id, numSongs: 9, lastSong: selectedSong?.id, state: self.state!)
        self.state!.group?.songs?.append(contentsOf: nextSongs)
        self.state!.currentActiveGroup = self.state!.group!.id
        Globals.addPlaylistSongs(songs: self.state!.group!.songs!, groupId: self.state!.group!.id, userId: self.state!.user.id)
    }
    
    func addToQueue(alert: UIAlertAction!) {
        self.state!.group!.songs!.append(self.selectedSong!)
        Globals.addPlaylistSongs(songs: self.state!.group!.songs!, groupId: self.state!.group!.id, userId: self.state!.user.id)
    }
    
    //MARK: Search Bar Functions
    
    func updateSearchResults(for searchController: UISearchController) {
        
        if (searchController.searchBar.text! != "") {
            NSLog("updateSearchResults")
            self.songs = filterSongs(query: searchController.searchBar.text!)
        } else {
            self.songs = self.state!.group!.totalSongs
        }
        self.songTable.reloadData()
        
    }
    
    func filterSongs(query: String) -> [Song] {
        let songs = self.state!.group!.totalSongs.filter({( song : Song) -> Bool in
            return song.name.lowercased().contains(query.lowercased())
        })
        return songs
    }
    
    func didSwipeRight() {
        self.performSegue(withIdentifier: "totalSongsBackSegue", sender: self)
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "totalSongsBackSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! ViewPlaylistViewController
            destinationVC.networkShown = true
            destinationVC.state = state
        }
    }
    
    func saveSong(alert: UIAlertAction!) {
        let query = "https://api.spotify.com/v1/me/tracks?ids=" + self.selectedSong!.id
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        let putParameters = "ids=" + self.selectedSong!.id
        request.setValue("Bearer \(self.state!.getAccessToken())", forHTTPHeaderField: "Authorization")
        
        Globals.sendRequest(request: request, postParameters: putParameters, method: "PUT", completion: { _ in }, isAsync: 1)
        
    }
}
