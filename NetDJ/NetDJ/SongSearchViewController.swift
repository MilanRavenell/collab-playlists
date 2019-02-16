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
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        rightSwipeGesture.direction = .right
        self.songTable.addGestureRecognizer(rightSwipeGesture)
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.center = self.view.center
        self.view.addSubview(activityIndicator)
        
        songTable.frame = CGRect(x: songTable.frame.minX, y: songTable.frame.minY, width: songTable.frame.width, height: view.frame.height - 250)
        labelView = UIView(frame: CGRect(x: 0, y: songTable.frame.maxY, width: view.frame.width, height: 50))
        labelView.backgroundColor = Globals.getThemeColor1()
        self.view.addSubview(labelView)
        
        let selectedLabel = UILabel(frame: CGRect(x: 10, y: 0, width: labelView.frame.width, height: labelView.frame.height))
        selectedLabel.text = "Selected :"
        selectedLabel.textColor = UIColor.white
        labelView.addSubview(selectedLabel)
        
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
            
            let delete_Button = UIButton(type: .system)
            delete_Button.setTitle("Delete", for: .normal)
            delete_Button.setTitleColor(UIColor.red, for: .normal)
            delete_Button.frame = CGRect(x: self.view.frame.size.width-100, y: 0, width: 100, height: cell.frame.height)
            delete_Button.addTarget(self, action: #selector(deleteBtnPressed), for: .touchUpInside)
            delete_Button.tag = indexPath.row
            cell.addSubview(delete_Button)
            
            cell.layoutIfNeeded()
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == songTable {
            selectedSong = songs[indexPath.row]
            if let id = self.state!.group?.id {
                var indx = self.state!.user.songs[id]?.index(where: { [weak self] (item) -> Bool in
                    item.id == self?.selectedSong?.id
                })
                if indx == nil {
                    indx = self.selectedSongs.index(where: { [weak self] (item) -> Bool in
                        item.id == self?.selectedSong?.id
                    })
                    if indx == nil {
                        self.selectedSongs.append(selectedSong!)
                        selectedSongTable.reloadData()
                        selectedHeaderLabel.text = String(self.selectedSongs.count) + " Selected"
                        view.endEditing(true)
                        self.searchController?.searchBar.resignFirstResponder()
                        self.searchController?.isActive = false
                        tableView.deselectRow(at: indexPath, animated: true)
                        return
                    }
                }
                view.endEditing(true)
                self.searchController?.searchBar.resignFirstResponder()
                self.searchController?.isActive = false
                tableView.deselectRow(at: indexPath, animated: true)
                Globals.showAlert(text: "You've already selected this song", view: self.view)
            }
            
            
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
                }
            } catch {
                print("\(error)")
            }
        }
        //executing the
        task.resume()
    }
    
    func didSwipeRight() {
        self.songsVC.songSearchVC = self
        self.navigationController?.popViewController(animated: true)
    }
    
    func animateSelectedSong(present: Bool) {
        if (present) {
            songTable.allowsSelection = false
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear, animations: { [weak self] in
                if let vc = self {
                    vc.labelView.frame = CGRect(x: 0, y: vc.view.frame.height-500, width: vc.view.frame.width, height: 50)
                    vc.selectedSongTable.frame = CGRect(x: 0, y: vc.labelView.frame.maxY, width: vc.view.frame.width, height: vc.view.frame.height - vc.labelView.frame.maxY)
                }
                }, completion: { (finished) in
                    return
            })
        } else {
            songTable.allowsSelection = true
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear, animations: { [weak self] in
                if let vc = self {
                    vc.labelView.frame = CGRect(x: 0, y: vc.view.frame.height-50, width: vc.view.frame.width, height: 50)
                    vc.selectedSongTable.frame = CGRect(x: 0, y: vc.labelView.frame.maxY, width: vc.view.frame.width, height: vc.view.frame.height - vc.labelView.frame.maxY)
                }
                }, completion: { (finished) in
                    return
            })
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        animateSelectedSong(present: false)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        animateSelectedSong(present: true)
    }
    
    func deleteBtnPressed(sender: UIButton!) {
        if sender.tag < selectedSongs.count {
            self.selectedSongs.remove(at: sender.tag)
            self.selectedSongTable.reloadData()
            selectedHeaderLabel.text = String(self.selectedSongs.count) + " Selected"
        }
    }
    
    // MARK: - Actions
    @IBAction func save(_ sender: Any) {
        self.state!.group?.network = [[Int]]()
        self.state!.group?.totalSongs = [Song]()
        self.state!.group?.totalSongsFinishedLoading = false
        if let id = self.state!.group?.id {
            self.state!.user.songs[id]?.append(contentsOf: selectedSongs)
            Globals.addUserSongs(songs: selectedSongs, userId: self.state!.user.id, groupId: id, fromPlaylist: 0)
        }
        
        
        if (self.state!.group?.id != -1) {
            
            let songsVC = self.songsVC
            let songsTable = self.songsVC.songsTable
            let emptyLabel = self.songsVC.emptyLabel
            let activityIndicator = self.songsVC.activityIndicator
            
            songsTable?.isHidden = true
            emptyLabel?.isHidden = true
            activityIndicator?.startAnimating()
            
            
            if let state = self.state {
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                    Globals.updateNetwork(group: state.group, state: state)
                    DispatchQueue.main.async {
                        songsVC?.mySongsDidFinishLoading()
                    }
                }
            }
        }
        
        self.songsVC.songSearchVC = self
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.songsVC.songSearchVC = self
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
}
