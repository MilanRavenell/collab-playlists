//
//  SongsViewController.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/16/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class SongsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {

    //MARK: Properties
    @IBOutlet weak var songsTable: UITableView!
    var searchController: UISearchController?
    var songs = [Song]()
    var selectedSong: Song?
    var state: State?
    var prevController: String?
    weak var viewPlaylistView: ViewPlaylistViewController?
    var activityIndicator: UIActivityIndicatorView?
    var emptyLabel: UILabel?
    var songSearchVC: SongSearchViewController?
    var userPlaylistVC: UserPlaylistsTableViewController?
    var errorLabel: UILabel!
    var retryBtn: UIButton!
    var selectedIndx: Int!
    var user: User!
    @IBOutlet weak var addBtn: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.state!.songsVC = self
        
        self.title = "Your Songs"
        
        if user == nil {
            user = self.state!.user
        } else {
            let name = user.name ?? user.id
            title = name + "'s Songs"
            addBtn.isEnabled = false
            DispatchQueue.global().async { [weak self] in
                if let user = self?.user {
                    if let state = self?.state {
                        if let id = self?.state!.group?.id {
                            Globals.getUserSongs(user: user, groupId: id, state: state)
                            
                            Globals.getUserSelectedPlaylists(user: user, groupId: id, state: state)
                            let playlists = Globals.getUserPlaylists(userId: user.id, state: state) ??  [Playlist]()
                            for playlist in playlists {
                                playlist.state = state
                                if let selectedPlaylists = user.selectedPlaylists[id], selectedPlaylists.contains(playlist.id) {
                                    user.songs[id]?.append(contentsOf: playlist.getSongs()  )
                                }
                            }
                        }
                        
                        self?.mySongsDidFinishLoading()
                    }
                }
            }
        }
        
        self.songsTable.frame = self.view.frame
        self.songsTable.rowHeight = 70
        self.songsTable.frame = CGRect(x: self.view.frame.minX, y: self.view.frame.minY, width: self.view.frame.width, height: self.view.frame.height - 20)
        songsTable.dataSource = self
        self.songsTable.delegate = self
        self.songsTable.tableFooterView = UIView()
        
        activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator?.center = self.view.center
        self.view.addSubview(activityIndicator!)
        
        emptyLabel = UILabel(frame: self.view.frame)
        emptyLabel?.text = "Click on the + to add songs!"
        emptyLabel?.textColor = UIColor.gray
        emptyLabel?.textAlignment = .center
        emptyLabel?.isHidden = true
        self.view.addSubview(emptyLabel!)
        
        retryBtn = UIButton(frame: CGRect(x: self.view.frame.minX, y: self.view.frame.minY + 25, width: self.view.frame.width, height: self.view.frame.height))
        retryBtn.setTitle("Retry", for: .normal)
        retryBtn.setTitleColor(Globals.getThemeColor1(), for: .normal)
        retryBtn.addTarget(self, action: #selector(retry), for: .touchUpInside)
        retryBtn.isHidden = true
        self.view.addSubview(retryBtn)
        
        activityIndicator?.startAnimating()
        
        if self.user.songsHasLoaded || (self.user.defaultsLoaded && viewPlaylistView == nil) {
            mySongsDidFinishLoading()
        }
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        rightSwipeGesture.direction = .right
        self.songsTable.addGestureRecognizer(rightSwipeGesture)
        self.view.addGestureRecognizer(rightSwipeGesture)
        
        searchController = UISearchController(searchResultsController: nil)
        
        if #available(iOS 10.0, *) {
            searchController?.hidesNavigationBarDuringPresentation = false
            searchController?.dimsBackgroundDuringPresentation = false
            self.definesPresentationContext = true
            searchController?.searchResultsUpdater = self
            searchController?.searchBar.sizeToFit()
            self.songsTable.tableHeaderView = searchController?.searchBar
        } else {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            searchController?.searchResultsUpdater = self
            searchController?.obscuresBackgroundDuringPresentation = false
            searchController?.searchBar.placeholder = "Search Songs"
            searchController?.hidesNavigationBarDuringPresentation = true
            searchController?.searchBar.tintColor = UIColor.white
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setSongsNoDuplicates()
        // Causes memory leak to get rid of view controller while searchcontroller is active
        DispatchQueue.main.async {
            self.songsTable.reloadData()
        }
        if songs.count > 0 {
            emptyLabel?.isHidden = true
        }
        if let songSearchVC = self.songSearchVC {
            songSearchVC.searchController?.isActive = false
            self.songSearchVC = nil
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return songs.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "SongTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? SongTableViewCell else{
            fatalError("It messed up")
        }
        
        cell.backgroundColor = UIColor.clear
        
        // Fetches the appropriate song
        let song = songs[indexPath.row]
        
        cell.songName.text = song.name
        cell.songArtist.text = song.artist
        cell.songArtist.font = cell.songArtist.font.withSize(15)
        
        if self.state!.group?.id == self.state!.curActiveId && self.viewPlaylistView?.curPlaylingId == song.id {
            cell.songName.textColor = Globals.getThemeColor1()
            cell.songArtist.textColor = Globals.getThemeColor1()
        } else {
            cell.songName.textColor = UIColor.black
            cell.songArtist.textColor = UIColor.black
        }
        
        let buttonsLabel = UILabel(frame: CGRect(x: view.frame.width - 40, y: cell.contentView.frame.minY, width: 40, height: cell.contentView.frame.height))
        buttonsLabel.text = "..."
        cell.contentView.addSubview(buttonsLabel)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedSong = songs[indexPath.row].copy() as? Song
        selectedIndx = indexPath.row
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
        
        if (viewPlaylistView != nil) {
            choices.append(("Play Now", "play_small.png", playNow))
            
            choices.append(("Add to Up Next", "hamburger.png", addToQueue))
            
            if (!self.state!.user.savedSongs.contains(selectedSong!.id)) {
                choices.append(("Save to Spotify Library", "icons8-add-new-50.png", saveSong))
            }
        }
        
        choices.append(("Delete", "icons8-waste-32.png", deleteBtnPressed))
        
        choices.append(("Cancel", "icons8-delete-40.png", nil))
        
        let choiceSelection = ChoiceSelection(titleView: titleView, choices: choices, view: view)
        choiceSelection.present(show: true)
        
        self.songsTable.deselectRow(at: indexPath, animated: true)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        if (searchController.searchBar.text! != "") {
            NSLog("updateSearchResults")
            self.songs = filterSongs(query: searchController.searchBar.text!)
        } else {
            setSongsNoDuplicates()
        }
        self.songsTable.reloadData()
        
    }
    
    func filterSongs(query: String) -> [Song] {
        if let id = self.state!.group?.id {
            let songs = (state!.user.songs[id] ?? [Song]()).filter({( song : Song) -> Bool in
                return song.name.lowercased().contains(query.lowercased())
            })
            return songs
        }
        return [Song]()
    }
    
    func playNow() {
        if let appRemote = self.state!.appRemote, let playerAPI = appRemote.playerAPI {
            self.viewPlaylistView?.playSong(playerAPI: playerAPI, song: self.selectedSong!)
        }
        
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
        self.songsTable.reloadData()
    }
    
    func addToQueue() {
        self.selectedSong?.loadPic()
        if let _ = self.state!.group?.songs {
            self.state!.group!.songs!.append(self.selectedSong!)
        }
        
        if let id = self.state!.group?.id {
            Globals.addPlaylistSongs(songs: self.state!.group?.songs ?? [Song](), groupId: id, userId: self.user.id)
        }
        
        Globals.showAlert(text: "Added to Up Next", view: self.view)
    }
    
    func saveSong() {
        let query = "https://api.spotify.com/v1/me/tracks?ids=" + self.selectedSong!.id!
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        let putParameters = "ids=" + self.selectedSong!.id
        request.setValue("Bearer \(self.state!.getAccessToken())", forHTTPHeaderField: "Authorization")
        
        Globals.sendRequest(request: request, postParameters: putParameters, method: "PUT", completion: { _ in }, isAsync: 1)
        
    }

    @objc func didSwipeRight() {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "addSongSegue") {
            let destinationVC = segue.destination as! SongSearchViewController
            destinationVC.prevController = prevController
            destinationVC.state = state
            destinationVC.songsVC = self
        }
        
        if (segue.identifier == "addPlaylistSegue") {
            let destinationVC = segue.destination as! UserPlaylistsTableViewController
            destinationVC.prevController = prevController
            destinationVC.state = state
        }
    }
    
    func deleteBtnPressed() {
        if selectedIndx >= songs.count {
            return
        }
        let song = songs[selectedIndx]
        songs.remove(at: selectedIndx)
        if let id = self.state!.group?.id {
            self.user.songs[id] = songs
            self.songsTable.beginUpdates()
            self.songsTable.deleteRows(at: [IndexPath(row: selectedIndx, section: 0)], with: .automatic)
            self.songsTable.endUpdates()
            
            Globals.deleteUserSongs(songs: [song], userId: self.user.id, groupId: id)
            
            DispatchQueue.global().async {
                Globals.updateNetwork(group: self.state!.group, state: self.state!)
            }
            
            if (self.user.songs[id]!.count == 0) {
                self.songsTable.reloadData()
                emptyLabel?.text = "These are the songs that will be automatically added everytime you join a group"
                emptyLabel?.textColor = UIColor.gray
                emptyLabel?.textAlignment = .center
                emptyLabel?.isHidden = false
            }
        }
    }
    
    @IBAction func unwindToSongView(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? SongSearchViewController {
            self.state = sourceViewController.state
            self.songsTable.reloadData()
        }
        
        if let sourceViewController = sender.source as? UserPlaylistsTableViewController {
            let playlists = sourceViewController.playlists
            let starting = sourceViewController.startingPlaylists
            
            songs = [Song]()
            state?.user.songsHasLoaded = false
            songsTable.reloadData()
            self.emptyLabel?.isHidden = true
            self.retryBtn.isHidden = true
            self.activityIndicator?.startAnimating()
            
            DispatchQueue.global().async { [weak self] in
                if let state = self?.state {
                    if let id = state.group?.id {
                        state.user.songs[id] = [Song]()
                        
                        Globals.updatePlaylist(group: state.group, playlists: playlists, startingPlaylists: starting, state: state)
                        Globals.getUserSongs(user: state.user, groupId: id, state: state)
                        Globals.getUserSelectedPlaylists(user: state.user, groupId: id, state: state)
                        
                        if let playlists = NSKeyedUnarchiver.unarchiveObject(withFile: Globals.playlistsFilePath) as? [Playlist] {
                            for playlist in playlists {
                                playlist.state = state
                                if let selectedPlaylists = state.user.selectedPlaylists[id], selectedPlaylists.contains(playlist.id) {
                                    state.user.songs[id]?.append(contentsOf: playlist.getSongs()  )
                                }
                            }
                        }
                        self?.mySongsDidFinishLoading()
                    }
                }
            }
        }
    }
    
    func mySongsDidFinishLoading() {
        if let id = self.state!.group?.id {
            if self.user.songs[id] == nil {
                DispatchQueue.main.async { [weak self] in
                    self?.songs = [Song]()
                    
                    self?.songsTable.reloadData()
                    self?.emptyLabel?.text = "Couldn't retrieve songs"
                    self?.emptyLabel?.isHidden = false
                    self?.retryBtn.isHidden = false
                }
                return
            }
            
            setSongsNoDuplicates()
            self.user.songsHasLoaded = true
            
            DispatchQueue.main.async { [weak self] in
                self?.songsTable.reloadData()
                self?.activityIndicator?.stopAnimating()
                self?.songsTable.isHidden = false
                if let songs = self?.songs, songs.count == 0 {
                    self?.songsTable.isHidden = true
                    self?.emptyLabel?.text = "Add songs!"
                    self?.emptyLabel?.isHidden = false
                } else {
                    self?.emptyLabel?.isHidden = true
                    self?.retryBtn.isHidden = true
                }
            }
        }
    }
    
    @objc func retry() {
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator?.startAnimating()
            self?.retryBtn.isHidden = true
            self?.emptyLabel?.isHidden = true
        }
        
        DispatchQueue.global().async { [weak self] in
            if let state = self?.state {
                if let id = state.group?.id {
                    if let user = self?.user {
                        Globals.getUserSongs(user: user, groupId: id, state: state)
                        self?.mySongsDidFinishLoading()
                    }
                }
            }
        }
    }
    
    @IBAction func addBtnPressed(_ sender: Any) {
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 40))
        titleView.backgroundColor = Globals.getThemeColor1()
        
        let titleLabel = UILabel(frame: CGRect(x: 15, y: 0, width: titleView.frame.width - 15, height: titleView.frame.height))
        titleLabel.text = "Add songs:"
        titleLabel.textColor = UIColor.white
        titleView.addSubview(titleLabel)
        
        var choices = [(String, String, (() -> Void)?)]()
        choices = [("Search for song", "icons8-waste-32.png", addSongs), ("Manage Spotify Playlists", "icons8-waste-32.png", addPlaylist)]
        choices.append(("Cancel", "icons8-waste-32.png", nil))
        
        let choiceSelection = ChoiceSelection(titleView: titleView, choices: choices, view: view)
        choiceSelection.present(show: true)
    }
    
    func addSongs() {
        performSegue(withIdentifier: "addSongSegue", sender: self)
    }
    
    func addPlaylist() {
        performSegue(withIdentifier: "addPlaylistSegue", sender: self)
    }
    
    func setSongsNoDuplicates() {
        if let id = state!.group?.id {
            songs = Array(Set(user.songs[id] ?? [Song]()))
        }
    }
}
