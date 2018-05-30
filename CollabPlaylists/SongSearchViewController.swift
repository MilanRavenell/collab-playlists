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
    var selectedSong: Song?
    var session: SPTSession!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if ((songTable) != nil) {
            songTable.dataSource = self
            songTable.delegate = self
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: Table Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "SongSearchTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? SongSearchTableViewCell else{
            fatalError("It messed up")
        }
        
        // Fetches the appropriate song
        let song = songs[indexPath.row]
        
        cell.songName.text = song.name
        cell.songArtist.text = song.artist
        
        // Configure the cell...
        
        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedSong = songs[indexPath.row]
        
        performSegue(withIdentifier: "selectSongSegue", sender: self)
    }
    
    
    //MARK: Search Bar Functions
    
    func updateSearchResults(for searchController: UISearchController) {
        getSongs(query: songSearchBar.text!)
        
        self.songTable.reloadData()
    }
    
    // MARK: Spotify Search Functions
    func getSongs(query: String) {
        
        songs = [Song]()
        
        let request = try? SPTSearch.createRequestForSearch(withQuery: query, queryType: SPTSearchQueryType.queryTypeTrack, accessToken: session.accessToken)
        
        let response: AutoreleasingUnsafeMutablePointer<URLResponse?>? = nil
        do {
            let data = try NSURLConnection.sendSynchronousRequest(request!, returning: response)
            NSLog("yayyyyyyyyyyyyyyyyyyyyyy")
        } catch {
            print("error")
        }
        
        
        
        
//        do {
//            if let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] {
//                
//            }
//        } catch let error as NSError {
//            print(error.localizedDescription)
//        }
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
