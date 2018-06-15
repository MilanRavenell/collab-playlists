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

    override func viewDidLoad() {
        super.viewDidLoad()

        self.getUserPlaylists()
        self.tableView.reloadData()
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
        return self.playlists.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Configure the cell...
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserPlaylistsTableViewCell", for: indexPath) as? UserPlaylistsTableViewCell else {
            fatalError("It messed up")
        }
        
        let playlist = self.playlists[indexPath.row]
        
        // Configure the cell...
        cell.nameLabel.text = playlist.name

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.addSongsFromPlaylist(id: playlists[indexPath.row].id)
        //parsing the response
        self.performSegue(withIdentifier: "selectPlaylistSegue", sender: self)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "userPlaylistsBackSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! SongSearchViewController
            destinationVC.state = state
        }
        if (segue.identifier == "selectPlaylistSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! SongTableViewController
            destinationVC.state = state
        }
    }
    
    // MARK: Helpers
    func getUserPlaylists() {
        let query = "https://api.spotify.com/v1/users/" + self.state!.userId + "/playlists"
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(self.state!.session.accessToken!)", forHTTPHeaderField: "Authorization")
        
        let response = sendRequestSync(request: request, postParameters: nil, method: "GET") as! [String: AnyObject]
        
        let playlists = response["items"] as! [[String: AnyObject]]
        for playlist in playlists {
            let id = playlist["id"] as! String
            let name = playlist["name"] as! String
            let newPlaylist = Playlist(name: name, id: id)
            self.playlists.append(newPlaylist!)
        }
    }
    
    func addSongsFromPlaylist(id: String) {
        let query = "https://api.spotify.com/v1/users/" + self.state!.userId + "/playlists/" + id
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(self.state!.session.accessToken!)", forHTTPHeaderField: "Authorization")
        
        let response = sendRequestSync(request: request, postParameters: nil, method: "GET") as! [String: AnyObject]
        
        let tracks = response["tracks"]!["items"] as! [[String: AnyObject]]
        
        var songs = [Song]()
        
        for track in tracks {
            let id = track["track"]!["id"] as! String
            let name = track["track"]!["name"] as! String
            let artists = track["track"]!["artists"] as! [[String: AnyObject]]
            let artist = artists[0]["name"] as! String
            
            let newSong = Song(name: name, artist: artist, id: id)
            songs.append(newSong!)
        }
        
        RequestWrapper.addUserSongs(songs: songs, userId: self.state!.userId, groupId: self.state!.group!.id, isTop: 0)
    }

}
