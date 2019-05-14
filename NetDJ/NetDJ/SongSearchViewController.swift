//
//  SongSearchViewController.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 3/19/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class SongSearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchBarDelegate {
    
    //MARK: Properties
    @IBOutlet weak var songTable: UITableView!
    var songs = [Song]()
    var state: State?
    var selectedSong: Song?
    var searchController: UISearchController?
    var prevController: String?
    var songsCountLabel: UILabel!
    weak var songsVC: SongsViewController!
    var activityIndicator: UIActivityIndicatorView!
    var labelView: UIView!
    @IBOutlet weak var selectedSongTable: UITableView!
    var selectedSongs = [Song]()
    var selectedHeaderLabel: UILabel!
    var keyboardHeight: CGFloat = 0
    var keyboardActive = false
    var selectedActive = false
    var dimView: UIView!
    var selectedSongsLabel: UILabel!
    var selectedIndexPath: IndexPath?
    var playlists = [Playlist]()
    var playlistsAsSong = [Song]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Add Songs"
        // Do any additional setup after loading the view.
        
        if ((songTable) != nil) {
            songTable.dataSource = self
            songTable.delegate = self
            songTable.frame = self.view.frame
            songTable.tableFooterView = UIView(frame: CGRect(x: 0, y: songTable.frame.maxY, width: songTable.frame.width, height: 50))
            songsCountLabel = UILabel(frame: songTable.tableFooterView!.frame)
            songsCountLabel.text = "0 Results"
            songsCountLabel.textAlignment = .center
            songsCountLabel?.textColor = UIColor.gray
            songTable.tableFooterView?.addSubview(songsCountLabel!)
        }
        
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchBar.delegate = self
        
        if #available(iOS 10.0, *) {
            searchController?.hidesNavigationBarDuringPresentation = false
            searchController?.dimsBackgroundDuringPresentation = false
            searchController?.searchResultsUpdater = self
            searchController?.searchBar.sizeToFit()
            self.songTable.tableHeaderView = searchController?.searchBar
        } else {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            searchController?.searchResultsUpdater = self
            searchController?.obscuresBackgroundDuringPresentation = false
            searchController?.searchBar.placeholder = "Search Songs"
            searchController?.hidesNavigationBarDuringPresentation = true
            searchController?.searchBar.tintColor = UIColor.white
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        }
        definesPresentationContext = true
        searchController?.searchBar.tintColor = Globals.getThemeColor1()
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        rightSwipeGesture.direction = .right
        self.songTable.addGestureRecognizer(rightSwipeGesture)
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.center = self.view.center
        self.view.addSubview(activityIndicator)
        
        labelView = UIView(frame: CGRect(x: 0, y: songTable.frame.maxY, width: view.frame.width, height: 50))
        labelView.backgroundColor = Globals.getThemeColor1()
        
        let path = UIBezierPath(roundedRect: labelView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10, height: 10))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        labelView.layer.mask = mask
        
        let labelGesture = UITapGestureRecognizer(target: self, action: #selector(self.selectedLabelViewTapped))
        self.labelView.addGestureRecognizer(labelGesture)

        self.view.addSubview(labelView)
        
        selectedSongsLabel = UILabel(frame: CGRect(x: 10, y: 0, width: labelView.frame.width, height: labelView.frame.height))
        selectedSongsLabel.text = "0 Selected"
        selectedSongsLabel.textColor = UIColor.white
        
        labelView.addSubview(selectedSongsLabel)
        
        selectedSongTable.dataSource = self
        selectedSongTable.delegate = self
        selectedSongTable.frame = CGRect(x: 0, y: labelView.frame.maxY, width: view.frame.width, height: view.frame.height - labelView.frame.maxY)
        selectedSongTable.rowHeight = 80
        selectedSongTable.tableFooterView = UIView()
        selectedSongTable.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: selectedSongTable.frame.width, height: 50))
        
        selectedHeaderLabel = UILabel(frame: CGRect(x: 0, y: 0, width: selectedSongTable.tableHeaderView!.frame.width, height: selectedSongTable.tableHeaderView!.frame.height))
        selectedHeaderLabel.text = "0 Selected"
        selectedHeaderLabel.textAlignment = .center
        selectedHeaderLabel.textColor = UIColor.gray
        selectedSongTable.tableHeaderView?.addSubview(selectedHeaderLabel)
        
        dimView = UIView(frame: view.bounds)
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        dimView.alpha = 0
        dimView.isUserInteractionEnabled = false
        
        self.view.addSubview(dimView)
        
        self.view.bringSubview(toFront: selectedSongTable)
        self.view.bringSubview(toFront: labelView)
        
        self.activityIndicator.startAnimating()
        
        // Get user's spotify playlists
        DispatchQueue.global().async { [weak self] in
            if let state = self?.state {
                self?.playlists = Globals.getUserPlaylists(userId: state.user.id, state: state) ?? [Playlist]()
                
                for playlist in self?.playlists ?? [Playlist]() {
                    let song = Song(name: playlist.name, artist: "Spotify Playlist", id: "XXxxplaylistxxXX" + playlist.id, imageURL: playlist.imageURL, state: state, loadNow: false)
                    song?.getPic()
                    if let song = song {
                        self?.playlistsAsSong.append(song)
                    }
                    
                }
                
                if self?.searchController?.searchBar.text == "" {
                    self?.songs = self?.playlistsAsSong ?? [Song]()
                    
                    DispatchQueue.main.async {
                        self?.activityIndicator.stopAnimating()
                        self?.songTable.reloadData()
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async { [weak self] in
            self?.searchController?.searchBar.becomeFirstResponder()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: Notification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: Notification.Name.UIKeyboardWillShow, object: nil)
    }
    
    @objc func keyboardWillAppear(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            keyboardHeight = keyboardFrame.cgRectValue.height
        }
        keyboardActive = true
        animateSelectedSong(show: false)
        songTable.frame = CGRect(x: songTable.frame.minX, y: songTable.frame.minY, width: songTable.frame.width, height: self.view.frame.height - 250)
    }
    
    @objc func keyboardWillDisappear(_ notification: Notification) {
        keyboardActive = false
        if !selectedActive {
            animateSelectedSong(show: false)
        }
        songTable.frame = CGRect(x: songTable.frame.minX, y: songTable.frame.minY, width: songTable.frame.width, height: self.view.frame.height)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    
    //MARK: Table Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == songTable {
            return songs.count
        } else {
            return selectedSongs.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == songTable {
            let cellIdentifier = "SongSearchTableViewCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? SongSearchTableViewCell else{
                fatalError("It messed up")
            }
            
            cell.backgroundColor = UIColor.clear
            
            let albumCover = UIImageView(frame: CGRect(x: 0, y: 0, width: 80, height: cell.frame.height))
            cell.addSubview(albumCover)
            
            // Fetches the appropriate song
            if (indexPath.row < self.songs.count) {
                let song = self.songs[indexPath.row]
                song.assignPicToView(imageView: albumCover)
                
                cell.songName.text = song.name
                cell.songArtist.text = song.artist
                cell.songArtist.font = cell.songArtist.font.withSize(15)
                
                // Make song text green if currently selected
                var indx = self.selectedSongs.index(where: { (item) -> Bool in
                    item.id == song.id
                })
                if indx != nil {
                    cell.songName.textColor = Globals.getThemeColor1()
                    cell.songArtist.textColor = Globals.getThemeColor1()
                } else {
                    cell.songName.textColor = UIColor.black
                    cell.songArtist.textColor = UIColor.black
                }
                
                // Make playlist text green if currently in network
                if let id = self.state!.group?.id {
                    indx = self.state!.user.selectedPlaylists[id]?.index(where: { (item) -> Bool in
                        item == song.id.suffix(16)
                    })
                    if indx != nil {
                        cell.songName.textColor = Globals.getThemeColor1()
                        cell.songArtist.textColor = Globals.getThemeColor1()
                    } else {
                        cell.songName.textColor = UIColor.black
                        cell.songArtist.textColor = UIColor.black
                    }
                }
            }

            return cell
        } else {
            let cellIdentifier = "SelectedSongTableViewCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? SelectedSongTableViewCell else{
                fatalError("It messed up")
            }
            
            cell.backgroundColor = UIColor.clear
            
            let albumCover = UIImageView(frame: CGRect(x: 0, y: 0, width: 80, height: cell.frame.height))
            cell.addSubview(albumCover)
            
            // Fetches the appropriate song
            if (indexPath.row < self.selectedSongs.count) {
                let song = self.selectedSongs[indexPath.row]
                song.assignPicToView(imageView: albumCover)
                
                cell.songName.text = song.name
                cell.songArtist.text = song.artist
                cell.songArtist.font = cell.songArtist.font.withSize(15)
            }
            
            cell.layoutIfNeeded()
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        selectedSong = songs[indexPath.row]
        self.searchController?.searchBar.resignFirstResponder()
        
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
//        choices = [("Play Now", "play_small.png", playNow), ("Add to Up Next", "hamburger.png", addToQueue)]
        
        if tableView == songTable {
            if let id = self.state!.group?.id {
                // If selected a playlist
                if selectedSong?.id.contains("XXxxplaylistxxXX") ?? false {
                    let indx = self.state!.user.selectedPlaylists[id]?.index(where: { (item) -> Bool in
                        item == selectedSong?.id.suffix(16) ?? ""
                    })
                    if indx == nil {
                        choices.append(("Add Playlist to Network", "icons8-waste-32.png", selectPlaylist))
                    } else {
                        choices.append(("Remove Playlist to Network", "icons8-waste-32.png", removePlaylist))
                    }
                    
                } else {
                    var indx = self.state!.user.songs[id]?.index(where: { [weak self] (item) -> Bool in
                        item.id == self?.selectedSong?.id
                    })
                    if indx == nil {
                        indx = self.selectedSongs.index(where: { [weak self] (item) -> Bool in
                            item.id == self?.selectedSong?.id
                        })
                        if indx == nil {
                            choices.append(("Add to Network", "icons8-waste-32.png", selectSong))
                        } else {
                            choices.append(("Remove Song", "icons8-waste-32.png", removeSong))
                        }
                    }
                    
                    choices.append(("Play Now", "play_small.png", playNow))
                    choices.append(("Add to Up Next", "hamburger.png", addToQueue))
                }
            }
        } else {
            choices.append(("Remove", "icons8-waste-32.png", removeSong))
        }
        
        choices.append(("Cancel", "icons8-delete-40.png", nil))
        
        let choiceSelection = ChoiceSelection(titleView: titleView, choices: choices, view: view)
        choiceSelection.present(show: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
        
    func playNow() {
        self.state!.viewPlaylistVC?.playSong(player: self.state!.player!, song: selectedSong!)
        self.selectedSong?.loadPic()
        self.state!.group?.songs?.insert(self.selectedSong!, at: 0)
        self.state?.curActiveId = self.state!.group?.id ?? self.state?.curActiveId
        self.state!.currentActiveGroup = nil
        DispatchQueue.global().async { [weak self] in
            if let state = self?.state {
                if let id = state.group?.id {
                    Globals.addPlaylistSongs(songs: state.group?.songs ?? [Song](), groupId: id, userId: state.user.id)
                }
            }
        }
        self.songTable.reloadData()
        self.searchController?.searchBar.becomeFirstResponder()
    }
    
    func addToQueue() {
        self.selectedSong?.loadPic()
        if let _ = self.state!.group?.songs {
            self.state!.group!.songs!.append(self.selectedSong!)
        }
        self.state!.viewPlaylistVC?.songs = self.state!.group?.songs ?? [Song]()
        
        if let id = self.state!.group?.id {
            Globals.addPlaylistSongs(songs: self.state!.group?.songs ?? [Song](), groupId: id, userId: self.state!.user.id)
        }
        
        Globals.showAlert(text: "Added to Up Next", view: self.view)
        self.searchController?.searchBar.becomeFirstResponder()
    }
    
    func selectSong() {
        if let selectedSong = self.selectedSong {
            if let selectedIndexPath = self.selectedIndexPath {
                self.songTable.deselectRow(at: selectedIndexPath, animated: true)
            }
            self.selectedSongs.append(selectedSong)
            selectedSongTable.reloadData()
            selectedHeaderLabel.text = String(self.selectedSongs.count) + " Selected"
            selectedSongsLabel.text = String(self.selectedSongs.count) + " Selected"
            songTable.reloadData()
            self.searchController?.searchBar.becomeFirstResponder()
        }
    }
    
    func removeSong() {
        if let selectedIndexPath = self.selectedIndexPath {
            self.selectedSongs.remove(at: selectedIndexPath.row)
        }
        
        selectedHeaderLabel.text = String(self.selectedSongs.count) + " Selected"
        selectedSongsLabel.text = String(self.selectedSongs.count) + " Selected"
        songTable.reloadData()
        selectedSongTable.reloadData()
        if selectedSongs.count == 0 {
            self.searchController?.searchBar.becomeFirstResponder()
        }
    }
    
    func selectPlaylist() {
        if let selectedPlaylist = self.selectedSong {
            if let id = self.state!.group?.id {
                self.state!.user.selectedPlaylists[id]?.append(String(selectedPlaylist.id.suffix(16)))
                
                let indx = self.playlists.index(where: { (item) -> Bool in
                    item.id == selectedPlaylist.id.suffix(16)
                })
                if (indx != nil) {
                    let playlist = self.playlists[indx!]
                    DispatchQueue.global().async {
                        Globals.addUserPlaylist(playlist: playlist, userId: self.state!.user.id, groupId: id)
                        Globals.addUserSongs(songs: playlist.getSongs(), userId: self.state!.user.id, groupId: id, fromPlaylist: 1)
                    }
                }
            }
            songTable.reloadData()
        }
    }
    
    func removePlaylist() {
        if let selectedPlaylist = self.selectedSong {
            if let id = self.state!.group?.id {
               
                // Remove from user selected playlists
                var indx = self.state!.user.selectedPlaylists[id]?.index(where: { (item) -> Bool in
                    item == selectedPlaylist.id.suffix(16)
                })
                if indx != nil {
                    self.state!.user.selectedPlaylists[id]?.remove(at: indx!)
                }
                
                indx = self.playlists.index(where: { (item) -> Bool in
                    item.id == selectedPlaylist.id.suffix(16)
                })
                if (indx != nil) {
                    let playlist = self.playlists[indx!]
                    DispatchQueue.global().async {
                        Globals.deleteUserPlaylist(id: playlist.id, userId: self.state!.user.id, groupId: id)
                        Globals.deleteUserSongs(songs: playlist.getSongs(), userId: self.state!.user.id, groupId: id)
                    }
                }
            }
            songTable.reloadData()
        }
    }

    //MARK: - Search Bar Functions
    
    func updateSearchResults(for searchController: UISearchController) {
        activityIndicator.startAnimating()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(getSongs), object: nil)
        self.perform(#selector(self.getSongs), with: nil, afterDelay: 0.5)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        getSongs()
    }

    
    // MARK: Spotify Search Functions
    func getSongs() {
        let query = searchController!.searchBar.text!
        var songs = [Song]()
        
        if query == "" {
            self.songTable.reloadData()
            self.songsCountLabel.text = String(songs.count) + " Results"
            self.activityIndicator.stopAnimating()
            print("searched!!")
            return
        }
        
        let request = try? SPTSearch.createRequestForSearch(withQuery: query, queryType: SPTSearchQueryType.queryTypeTrack, accessToken: self.state!.getAccessToken())
        
        var JSON: [String: [String: AnyObject]]?
        
        let task = URLSession.shared.dataTask(with: request as! URLRequest) { [weak self]
            data, response, error in
            
            if error != nil {
                print("error is \(String(describing: error))")
                return;
            }
            
            //parsing the response
            do {
                //converting resonse to NSDictionary
                JSON  = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: [String: AnyObject]]
                if let tracks = JSON?["tracks"]?["items"] as? [[String: AnyObject]] {
                    for track in tracks {
                        let name = track["name"] as? String ?? "Not Found"
                        let id = track["id"] as? String ?? "Not Found"
                        var artists = ""
                        let artistsDict = track["artists"] as? [[String: AnyObject]] ?? []
                        for artist in artistsDict {
                            artists += (artist["name"] as? String ?? "")
                            artists += ", "
                        }
                        if artistsDict.count > 0 {
                            artists.removeLast(2)
                        }
                        let album = track["album"] as? [String: AnyObject]
                        let pictures = album?["images"] as? [[String: AnyObject]]
                        let albumCover = pictures?[0]["url"] as? String
                        if let state = self?.state {
                            let song = Song(name: name, artist: artists, id: id, imageURL: albumCover, state: state, loadNow: true)
                            songs.append(song!)
                        }
                    }
                    self?.songs = songs
                    DispatchQueue.main.async {
                        self?.songTable.reloadData()
                        self?.songsCountLabel.text = String(songs.count) + " Results"
                        self?.activityIndicator.stopAnimating()
                        print("searched!!")
                    }
                    
                    let searchedPlaylists = self?.playlistsAsSong.filter({(playlist : Song) -> Bool in
                        return playlist.name.lowercased().contains(query.lowercased())
                    })
                    
                    self?.songs.insert(contentsOf: searchedPlaylists ?? [Song](), at: 0)
                }
            } catch {
                print("\(error)")
            }
        }
        //executing the
        task.resume()
    }
    
    func didSwipeRight() {
        if prevController != "ViewPlaylist" {
            self.songsVC.songSearchVC = self
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    // stage 0: top of screen
    // stage 1: top of keyboard
    // stage 2: bottom of screen
    func animateSelectedSong(show: Bool) {
        if show {
            selectedActive = true
            songTable.allowsSelection = false
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear, animations: { [weak self] in
                if let vc = self {
                    vc.labelView.frame = CGRect(x: 0, y: 130, width: vc.view.frame.width, height: 50)
                    vc.selectedSongTable?.frame = CGRect(x: 0, y: vc.labelView.frame.maxY, width: vc.view.frame.width, height: vc.view.frame.height - vc.labelView.frame.maxY)
                    vc.dimView?.alpha = 1
                }
                }, completion: { (finished) in
                    return
            })
        } else {
            songTable.allowsSelection = true
            selectedActive = false
            if keyboardActive {
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear, animations: { [weak self] in
                    if let vc = self {
                        vc.labelView?.frame = CGRect(x: 0, y: vc.view.frame.height - vc.keyboardHeight - 50, width: vc.view.frame.width, height: 50)
                        if let selectedSongTable = vc.selectedSongTable {
                            selectedSongTable.frame = CGRect(x: 0, y: vc.labelView.frame.maxY, width: vc.view.frame.width, height: vc.view.frame.height - vc.labelView.frame.maxY)
                        }
                        vc.dimView?.alpha = 0
                    }
                    }, completion: { (finished) in
                        return
                })
            } else {
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear, animations: { [weak self] in
                    if let vc = self {
                        vc.labelView.frame = CGRect(x: 0, y: vc.view.frame.height-50, width: vc.view.frame.width, height: 50)
                        vc.selectedSongTable?.frame = CGRect(x: 0, y: vc.labelView.frame.maxY, width: vc.view.frame.width, height: vc.view.frame.height - vc.labelView.frame.maxY)
                        vc.dimView?.alpha = 0
                    }
                    }, completion: { (finished) in
                        return
                })
            }
        }
    }
    
    func deleteBtnPressed(sender: UIButton!) {
        if sender.tag < selectedSongs.count {
            self.selectedSongs.remove(at: sender.tag)
            self.selectedSongTable.reloadData()
            selectedHeaderLabel.text = String(self.selectedSongs.count) + " Selected"
            selectedSongsLabel.text = String(self.selectedSongs.count) + " Selected"
        }
    }
    
    // MARK: - Actions
    @IBAction func save(_ sender: Any) {
        self.state!.group?.network = [[Int]]()
        self.state!.group?.totalSongs = [Song]()
        self.state!.group?.totalSongsFinishedLoading = false
        
        if let id = self.state!.group?.id {
            self.state!.user.songs[id]?.append(contentsOf: self.selectedSongs)
            Globals.addUserSongs(songs: self.selectedSongs, userId: self.state!.user.id, groupId: id, fromPlaylist: 0)
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancel(_ sender: Any) {
        if prevController != "ViewPlaylist" {
            self.songsVC.songSearchVC = self
        }
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    func selectedLabelViewTapped() {
        if selectedActive {
            animateSelectedSong(show: false)
        } else {
            animateSelectedSong(show: true)
        }
    }
}
