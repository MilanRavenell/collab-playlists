//
//  EventTableViewController.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 3/26/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class EventTableViewController: UITableViewController {
    
    //MARK: Properties
    var groups = [Group]()
    var session: SPTSession!
    var userId: String?
    var selectedGroup: Group?
    var player: SPTAudioStreamingController?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.groups = getGroups()
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
        return groups.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EventTableViewCell", for: indexPath) as? EventTableViewCell else {
            fatalError("It messed up")
        }
        
        let group = self.groups[indexPath.row]
        let name = getUsersName(id: group.admin)

        // Configure the cell...
        if (group.name != nil) {
            cell.groupName.text = group.name
        } else {
            cell.groupName.text = name + "'s Group"
        }
        
        cell.admin.text = name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedGroup = groups[indexPath.row]
        //parsing the response
        self.performSegue(withIdentifier: "viewGroups", sender: self)
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
    
    //MARK: Actions
    
    // FIX THIS
    
    @IBAction func addGroupPressed(_ sender: Any) {
        //created NSURL
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let requestURL = URL(string: "http://autocollabservice.com/creategroup")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "admin=" + self.userId!
        
        //adding the parameters to request body
        request.httpBody = postParameters.data(using: String.Encoding.utf8)
        
        //setting the method to post
        request.httpMethod = "POST"
        
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
                    let groupId = parseJSON["groupId"] as? Int
                    self.selectedGroup = Group(name: nil, admin: self.userId!, id: groupId!, activated: false, users: [self.userId!])
                }
                
                RequestWrapper.addGroupUser(groupId: self.selectedGroup!.id, userId: self.userId!)
                
            } catch {
                NSLog("\(error)")
            }
            
        }
        //executing the task
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        
        NSLog("gettingTopSongs")
        
        let topSongs = self.getTopSongs(userId: self.userId!, num: 20)
        for song in topSongs {
            self.addUserSong(song: song, groupId: self.selectedGroup!.id)
        }
        
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        if (segue.identifier == "mySongSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! SongTableViewController
            destinationVC.session = session
            destinationVC.userId = userId!
        }
        if (segue.identifier == "viewGroups") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! GroupViewController
            destinationVC.session = session
            destinationVC.userId = userId!
            destinationVC.group = selectedGroup!
            destinationVC.player = player!
        }
    }
    
    // MARK: Helpers
    
    
    func getTopSongs(userId: String, num: Int) -> [Song] {
        var additionalTracks = [Song]()
        let query = "https://api.spotify.com/v1/me/top/tracks?limit=\(num)"
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(session.accessToken!)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            do {
                
                //converting resonse to NSDictionary
                let myJSON =  try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String:AnyObject]
                
                if let parseJSON = myJSON {
                    let tracks = parseJSON["items"] as! [[String: AnyObject]]
                    for track in tracks {
                        let id = track["id"] as! String
                        let name = track["name"] as! String
                        let artists = track["artists"] as? [[String: AnyObject]]
                        var artistName =  artists?[0]["name"] as? String
                        if (artistName == nil) {
                            artistName = "Not Found"
                        }
                        let newSong = Song(name: name, artist: artistName!, id: id)
                        additionalTracks.append(newSong!)
                    }
                }
                NSLog("\(additionalTracks)")
                semaphore.signal()
            } catch {
                NSLog("\(error)")
            }
            
            NSLog("\(String(describing: data))")
        }
        //executing the task
        task.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        return additionalTracks
    }
    
    func addUserSong(song: Song, groupId: Int) {
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let requestURL = URL(string: "http://autocollabservice.com/addusersong")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        var postParameters = "groupId=\(groupId)" + "&userId=" + self.userId!
        postParameters = postParameters + "&songId=" + song.id + "&songName=" + song.name + "&songArtist=" + song.artist + "&isTop=1"
        
        //adding the parameters to request body
        request.httpBody = postParameters.data(using: String.Encoding.utf8)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            if error != nil{
                print("error is \(String(describing: error))")
                return;
            }
            
            NSLog("\(String(describing: data))")
            semaphore.signal()
        }
        //executing the task
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
    }
    
    func getUsersName(id: String) -> String {
        var name: String?
        
        let query = "https://api.spotify.com/v1/users/" + id
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(session.accessToken!)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            do {
                
                //converting resonse to NSDictionary
                let myJSON =  try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String:AnyObject]
                
                if let parseJSON = myJSON {
                    name = parseJSON["display_name"] as? String
                    if (name == nil) {
                        name = ""
                    }
                }
                
                semaphore.signal()
            } catch {
                NSLog("\(error)")
            }
            
            NSLog("\(String(describing: data))")
        }
        //executing the task
        task.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        return name!
    }
    
    func getGroups() -> [Group] {
        
        var groups = [Group]()
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getallgroups")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //setting the method to post
        request.httpMethod = "POST"
        
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
                let myJSON =  try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [[String: AnyObject]]
                
                //parsing the json
                if let results = myJSON {
                    for group in results {
                        NSLog("group")
                        let name = group["name"] as? String
                        let admin = group["admin"] as! String
                        let id = group["id"] as! Int
                        let activated = group["activated"] as! Bool
                        let newGroup = Group(name: name, admin: admin, id: id, activated: activated, users:[])
                        groups.append(newGroup!)
                    }
                    semaphore.signal()
                }
            } catch {
                NSLog("\(error)")
            }
            
        }
        //executing the task
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        
        for group in groups {
            group.users = getGroupUsers(id: group.id)
        }
        
        return groups
    }
    
    func getGroupUsers(id: Int) -> [String] {
        var users = [String]()
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getgroupusers")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(id)"
        
        //adding the parameters to request body
        request.httpBody = postParameters.data(using: String.Encoding.utf8)
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task2 = URLSession.shared.dataTask(with: request as URLRequest) {
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
                    NSLog("user")
                    users = parseJSON["users"]! as! [String]
                }
                
            } catch {
                NSLog("\(error)")
            }
            semaphore.signal()
        }
        //executing the
        task2.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        return users
    }
}
