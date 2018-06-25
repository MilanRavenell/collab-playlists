//
//  SongTableViewController.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 3/17/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class SongTableViewController: UITableViewController {
    
    //MARK: Properties
    var songs = [Song]()
    var state: State?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.getUserSongs()
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return songs.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "SongTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? SongTableViewCell else{
            fatalError("It messed up")
        }
        NSLog("Begin")
        
        // Fetches the appropriate song
        let song = songs[indexPath.row]
        
        cell.songName.text = song.name
        cell.songArtist.text = song.artist

        // Add delete Button
        let track_Button = UIButton()
        track_Button.setTitle("Delete", for: .normal)
        track_Button.setTitleColor(UIColor.blue, for: .normal)
        track_Button.frame = CGRect(x: self.view.frame.size.width-100, y: 0, width: 100, height: 90)
        //track_Button.backgroundColor = UIColor.gray
        track_Button.addTarget(self, action: #selector(SongTableViewController.deleteBtnPressed), for: .touchUpInside)
        track_Button.tag = indexPath.row
        cell.addSubview(track_Button)
        
        return cell
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
        if (segue.identifier == "addSongSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! SongSearchViewController
            destinationVC.state = state
        }
        
        if (segue.identifier == "songTableBackSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! ViewPlaylistViewController
            destinationVC.state = state
        }
    }
    
    // MARK: Helpers
    func getUserSongs() {
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getusersongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        //creating the post parameter by concatenating the keys and values from text field
        
        let postParameters = "userId=" + self.state!.userId + "&groupId=\(self.state!.group!.id)&onlyAdded=1"
        
        //adding the parameters to request body
        request.httpBody = postParameters.data(using: String.Encoding.utf8)
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            if error != nil{
                print("error is \(String(describing: error))")
                return;
            }
            
            NSLog("\(String(describing: data))")
            
            //parsing the response
            do {
                //converting resonse to NSDictionary
                let myJSON =  try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: AnyObject]
                
                
                //parsing the json
                if let parseJSON = myJSON {
                    let songs = parseJSON["songs"]! as! [[AnyObject]]
                    for song in songs {
                        let name = song[1] as! String
                        let artist = song[2] as! String
                        let id = song[0] as! String
                        let newSong = Song(name: name, artist: artist, id: id)
                        self.songs.append(newSong!)
                        
                    }
                }
                
            } catch {
                NSLog("\(error)")
            }
            semaphore.signal()
            
        }
        //executing the task
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
    }
    
    func deleteBtnPressed(sender: UIButton!) {
        
        // Track Functionality
        print("Add Track Functionality here")
        let song = songs[sender.tag]
        songs.remove(at: sender.tag)
        self.tableView.reloadData()
        
        RequestWrapper.updateNetworkAsync(add_delete: 1, user: self.state!.userId, songs: [song])
        RequestWrapper.deleteUserSongs(songs: [song], userId: self.state!.userId, groupId: self.state!.group!.id)
    }
}
