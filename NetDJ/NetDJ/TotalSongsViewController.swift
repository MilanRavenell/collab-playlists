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
    var songsCountLabel: UILabel!
    weak var viewPlaylistView: ViewPlaylistViewController?
    @IBOutlet weak var backBtn: UIBarButtonItem!
    var emptyLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Network Library"
        self.songs = [Song]()
        
        self.state?.totalSongsVC = self

        if ((songTable) != nil) {
            songTable.dataSource = self
            songTable.delegate = self
            songTable.frame = self.view.frame
            songTable.tableFooterView = UIView(frame: CGRect(x: 0, y: songTable.frame.maxY, width: songTable.frame.width, height: 50))
            
            songsCountLabel = UILabel(frame: songTable.tableFooterView!.frame)
            songsCountLabel.textAlignment = .center
            songsCountLabel?.textColor = UIColor.gray
            songTable.tableFooterView?.addSubview(songsCountLabel!)
            songTable.rowHeight = 70
            songTable.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: songTable.frame.width, height: 50))
            
            let headerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: songTable.tableHeaderView!.frame.width, height: songTable.tableHeaderView!.frame.height))
            headerLabel.text = "Ordered By Popularity"
            headerLabel.textAlignment = .center
            headerLabel.textColor = UIColor.gray
            songTable.tableHeaderView?.addSubview(headerLabel)
        }
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator?.center = self.view.center
        self.view.addSubview(activityIndicator!)
        
        if let totalSongsFinshedLoading = self.state!.group?.totalSongsFinishedLoading, totalSongsFinshedLoading {
            self.songs = self.state!.group?.totalSongs ?? [Song]()
            songsCountLabel?.text = String(self.songs.count) + " Songs"
        } else {
            activityIndicator?.startAnimating()
        }
        
        searchController = UISearchController(searchResultsController: nil)
        
        if #available(iOS 10.0, *) {
            searchController?.hidesNavigationBarDuringPresentation = false
            searchController?.dimsBackgroundDuringPresentation = false
            self.definesPresentationContext = true
            searchController?.searchResultsUpdater = self
            searchController?.searchBar.sizeToFit()
            searchController?.searchBar.placeholder = "Ordered by Popularity"
            self.songTable.tableHeaderView = searchController?.searchBar
        } else {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            searchController?.searchResultsUpdater = self
            searchController?.obscuresBackgroundDuringPresentation = false
            searchController?.searchBar.placeholder = "Ordered by Popularity"
            searchController?.hidesNavigationBarDuringPresentation = true
            searchController?.searchBar.tintColor = UIColor.white
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        }
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        rightSwipeGesture.direction = .right
        self.songTable.addGestureRecognizer(rightSwipeGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let userDefaults = UserDefaults.standard
        if userDefaults.object(forKey: "ViewLibraryHelpAlert") == nil {
            let alert = UIAlertController(title: "Welcome to your library!", message: "Click on a song to play it now or add it to your queue", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Okay!", style: .cancel, handler: nil))
            
            self.present(alert, animated: true)
            
            let requestedFbData = NSKeyedArchiver.archivedData(withRootObject: true)
            userDefaults.set(requestedFbData, forKey: "ViewLibraryHelpAlert")
            userDefaults.synchronize()
        }
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
        
        
        // Fetches the appropriate song
        let song = self.songs[indexPath.row]
        
        cell.name.text = song.name
        cell.name.frame = CGRect(x: cell.name.frame.minX, y: cell.name.frame.minY, width: cell.frame.width - cell.name.frame.minX, height: cell.name.frame.height)
        
        cell.artist.text = song.artist
        
        cell.artist.frame = CGRect(x: cell.artist.frame.minX, y: cell.artist.frame.minY, width: cell.frame.width - cell.artist.frame.minX, height: cell.artist.frame.height)
        
        cell.artist.font = cell.artist.font.withSize(15)
        
        if self.state!.group?.id == self.state!.curActiveId && self.viewPlaylistView?.curPlaylingId == song.id {
            cell.name.textColor = Globals.getThemeColor1()
            cell.artist.textColor = Globals.getThemeColor1()
        } else {
            cell.name.textColor = UIColor.black
            cell.artist.textColor = UIColor.black
        }
        
//        let buttonsLabel = UILabel(frame: CGRect(x: view.frame.width - 40, y: cell.contentView.frame.minY, width: 40, height: cell.contentView.frame.height))
//        buttonsLabel.text = "..."
//        cell.contentView.addSubview(buttonsLabel)
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedSong = self.songs[indexPath.row].copy() as? Song
        
        selectedSong?.loadPic()
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 100))
        let imageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 80, height: 80))
        selectedSong?.assignPicToView(imageView: imageView)
        let name = UILabel(frame: CGRect(x: 100, y: 25, width: view.frame.width - 100, height: 50))
        name.textColor = UIColor.white
        name.text = selectedSong?.name
        name.font = name.font.withSize(25)
        let artist = UILabel(frame: CGRect(x: 100, y: 53, width: view.frame.width - 100, height: 50))
        artist.textColor = UIColor.white
        artist.text = selectedSong?.artist
        artist.font = artist.font.withSize(15)
        titleView.addSubview(imageView)
        titleView.addSubview(name)
        titleView.addSubview(artist)
        
        var choices = [(String, String, (() -> Void)?)]()
        choices = [("Play Now", "play_small.png", playNow), ("Add to Up Next", "hamburger.png", addToQueue)]
        
        if (!self.state!.user.savedSongs.contains(selectedSong!.id)) {
            choices.append(("Save to Spotify Library", "icons8-add-new-50.png", saveSong))
        }
        choices.append(("Cancel", "icons8-delete-40.png", nil))
        
        let choiceSelection = ChoiceSelection(titleView: titleView, choices: choices, view: view)
        choiceSelection.present(show: true)

        self.songTable.deselectRow(at: indexPath, animated: true)
    }
    
    func playNow() {
        self.viewPlaylistView?.playSong(player: self.state!.player!, song: selectedSong!)
        self.selectedSong?.loadPic()
        self.state!.group?.songs = [self.selectedSong!]
        self.state?.curActiveId = self.state!.group?.id ?? self.state?.curActiveId
        self.state!.currentActiveGroup = nil
        DispatchQueue.global().async { [weak self] in
            if let state = self?.state {
                Globals.generateSongs(group: state.group, numSongs: 9, lastSong: self?.selectedSong, state: state, viewPlaylistVC: self?.viewPlaylistView)
                if let id = state.group?.id {
                    Globals.addPlaylistSongs(songs: state.group?.songs ?? [Song](), groupId: id, userId: state.user.id)
                }
            }
        }
        self.songTable.reloadData()
    }
    
    func addToQueue() {
        self.selectedSong?.loadPic()
        if let _ = self.state!.group?.songs {
            self.state!.group!.songs!.append(self.selectedSong!)
        }
        self.viewPlaylistView?.songs = self.state!.group?.songs ?? [Song]()
        
        if let id = self.state!.group?.id {
            Globals.addPlaylistSongs(songs: self.state!.group?.songs ?? [Song](), groupId: id, userId: self.state!.user.id)
        }
        
        Globals.showAlert(text: "Added to Up Next", view: self.view)
    }
    
    //MARK: Search Bar Functions
    
    func updateSearchResults(for searchController: UISearchController) {
        
        if (searchController.searchBar.text! != "") {
            NSLog("updateSearchResults")
            self.songs = filterSongs(query: searchController.searchBar.text!)
        } else {
            self.songs = self.state!.group?.totalSongs ?? [Song]()
        }
        self.songTable.reloadData()
        
    }
    
    func filterSongs(query: String) -> [Song] {
        if let group = self.state!.group {
            let songs = group.totalSongs.filter({( song : Song) -> Bool in
                return song.name.lowercased().contains(query.lowercased())
            })
            return songs
        }
        return [Song]()
    }
    
    func didSwipeRight() {
        if self.searchController!.isActive {
            viewPlaylistView?.totalSongsVC = self
        }
        navigationController?.popViewController(animated: true)
    }

    @IBAction func refresh(_ sender: Any) {
        self.songs = []
        self.songTable.reloadData()
        self.songsCountLabel.text = ""
        self.activityIndicator?.startAnimating()
        DispatchQueue.global().async { [weak self] in
            if let state = self?.state {
                Globals.updateNetwork(group: state.group, state: state)
                DispatchQueue.main.async {
                    self?.songs = state.group?.totalSongs ?? [Song]()
                    self?.songTable.reloadData()
                    self?.songTable.isHidden = false
                    self?.activityIndicator?.stopAnimating()
                    if let songs = self?.songs {
                        self?.songsCountLabel.text = String(songs.count) + " Songs"
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
    func saveSong() {
        let query = "https://api.spotify.com/v1/me/tracks?ids=" + self.selectedSong!.id!
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        let putParameters = "ids=" + self.selectedSong!.id
        request.setValue("Bearer \(self.state!.getAccessToken())", forHTTPHeaderField: "Authorization")
        
        Globals.sendRequest(request: request, postParameters: putParameters, method: "PUT", completion: { _ in }, isAsync: 1)
    }
    
    func totalSongsDidFinishLoading() {
        self.songs = self.state!.group?.totalSongs ?? [Song]()
        
        DispatchQueue.main.async { [weak self] in
            self?.songTable.reloadData()
            self?.activityIndicator?.stopAnimating()
            if let songs = self?.songs {
                self?.songsCountLabel?.text = String(songs.count) + " Songs"
            }
        }
    }
}
