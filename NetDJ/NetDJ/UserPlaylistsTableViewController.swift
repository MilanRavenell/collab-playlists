//
//  UserPlaylistsTableViewController.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 6/9/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class UserPlaylistsTableViewController: UITableViewController {
    
    //MARK: Properties
    var state: State?
    var playlists = [Playlist]()
    var startingPlaylists = [String]()
    var selectedPlaylists = [Playlist]()
    var prevController: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Your Playlists"
        
        self.tableView.reloadData()
        self.tableView.backgroundColor = Globals.getThemeColor2()
        
        navigationController?.navigationBar.barTintColor = Globals.getThemeColor1()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        for selectedPlaylist in self.state!.user.playlists[self.state!.group!.id]!.filter({ (playlist) -> Bool in
            return playlist.selected
        }) {
            startingPlaylists.append(selectedPlaylist.id)
        }
        
        if (self.state?.group == nil) {
            performSegue(withIdentifier: "userPlaylistBackToTableSegue", sender: self)
        }
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        rightSwipeGesture.direction = .right
        self.tableView.addGestureRecognizer(rightSwipeGesture)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.state!.user.playlists[self.state!.group!.id]!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Configure the cell...
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserPlaylistsTableViewCell", for: indexPath) as? UserPlaylistsTableViewCell else {
            fatalError("It messed up")
        }
        
        cell.backgroundColor = UIColor.clear
        
        let playlist = self.state!.user.playlists[self.state!.group!.id]![indexPath.row]
        
        // Configure the cell...
        cell.nameLabel.text = playlist.name
        if (playlist.selected) {
            cell.nameLabel.textColor = Globals.getThemeColor1()
        } else {
            cell.nameLabel.textColor = UIColor.black
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let playlist = self.state!.user.playlists[self.state!.group!.id]![indexPath.row]
        self.state!.user.playlists[self.state!.group!.id]![indexPath.row].selected = !playlist.selected
        self.tableView.reloadData()
    }
    
    func didSwipeRight() {
        backBtnPressed(self)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "userPlaylistsBackSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! ViewPlaylistViewController
            destinationVC.networkShown = true
            destinationVC.state = state
        }
        if (segue.identifier == "userPlaylistBackToTableSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! NetworkTableViewController
            self.state!.group = nil
            destinationVC.state = state
            destinationVC.userShown = true
        }
    }
    
    // MARK: Actions
    @IBAction func backBtnPressed(_ sender: Any) {
        self.updatePlaylist(groupId: self.state!.group!.id)
        
        if (self.prevController == "ViewPlaylist") {
            self.performSegue(withIdentifier: "userPlaylistsBackSegue", sender: self)
        }
        if (self.prevController == "User") {
            self.performSegue(withIdentifier: "userPlaylistBackToTableSegue", sender: self)
        }
    }
    
    
    // MARK: Helpers
    func updatePlaylist(groupId: Int) {
        var songs = [Song]()
        DispatchQueue.global().async {
            for playlist in self.state!.user.playlists[groupId]! {
                // Remove playlist
                if (self.startingPlaylists.contains(playlist.id) && !playlist.selected) {
                    if (playlist.id == Globals.topSongsToken) {
                        songs = self.state!.user.topSongs
                    } else {
                        songs = Globals.getSongsFromPlaylist(userId: self.state!.user.id, id: playlist.id, state: self.state!)
                    }
                    
                    Globals.deleteUserPlaylist(id: playlist.id, userId: self.state!.user.id, groupId: groupId)
                    Globals.updateNetworkAsync(groupId: groupId, add_delete: 1, user: self.state!.user.id, songs: songs)
                }
                // Add Playlist
                else if (!self.startingPlaylists.contains(playlist.id) && playlist.selected) {
                    if (playlist.id == Globals.topSongsToken) {
                        songs = self.state!.user.topSongs
                    } else {
                        songs = Globals.getSongsFromPlaylist(userId: self.state!.user.id, id: playlist.id, state: self.state!)
                    }
                    
                    self.state!.userNetworks[groupId]?.totalSongs.append(contentsOf: songs)
                    
                    Globals.addUserPlaylist(playlist: playlist, userId: self.state!.user.id, groupId: groupId)
                    Globals.updateNetworkAsync(groupId: groupId, add_delete: 0, user: self.state!.user.id, songs: songs)
                }
            }
        }
    }
}
