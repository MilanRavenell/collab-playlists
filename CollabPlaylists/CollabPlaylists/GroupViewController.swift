//
//  GroupViewController.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 3/26/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class GroupViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: Properties
    @IBOutlet weak var nameButton: UIButton!
    @IBOutlet weak var usersTable: UITableView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var nameLabel: UILabel!
    var state: State?
    var users = [String]()
    var useTop: Int!
    @IBOutlet weak var joinActivateButton: UIButton!
    @IBOutlet weak var viewPlaylistBtn: UIBarButtonItem!
    @IBOutlet weak var useTopSongsSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if ((usersTable) != nil) {
            usersTable.dataSource = self
            usersTable.delegate = self
        }
        
        useTopSongsSwitch.addTarget(self, action: #selector(self.toggleSwitch), for: .valueChanged)
        
        if (self.state?.group!.users?.contains(self.state!.userId))! {
            useTop = self.getUseTop(userId: self.state!.userId, groupId: self.state!.group!.id)
        }
        
        if (useTop == 1) {
            useTopSongsSwitch.isOn = true
        } else {
            useTopSongsSwitch.isOn = false
        }
        
        // If admin, then allow admin to activate/deactivate
        // If not admin, then let user leave/join
        if (self.state!.group!.admin == self.state!.userId) {
            self.joinActivateButton.setTitle("Delete Group", for: .normal)
        }
        
        if (!(self.state!.group!.users?.contains(self.state!.userId!))!) {
            self.viewPlaylistBtn.isEnabled = false
            useTopSongsSwitch.isEnabled = false
        }
        
        if (self.state!.group!.admin != self.state!.userId! && (self.state!.group!.users?.contains(self.state!.userId!))!) {
            self.joinActivateButton.setTitle("Leave Group", for: .normal)
        }
        
        if (self.state!.group!.admin != self.state!.userId! && !(self.state!.group!.users?.contains(self.state!.userId!))!) {
            self.joinActivateButton.setTitle("Join Group", for: .normal)
        }

        
        // If the group has a name, display name
        if (self.state!.group?.name == nil && self.state!.group?.admin == self.state!.userId) {
            nameLabel.isHidden = true
        } else if (self.state!.group?.name != nil && self.state!.group?.admin == self.state!.userId) {
            nameLabel.text = self.state!.group?.name
            nameTextField.isHidden = true
            nameButton.setTitle("Rename Group", for: .normal)
        } else if (self.state!.group?.name == nil && self.state!.group?.admin != self.state!.userId) {
            nameTextField.isHidden = true
            nameLabel.text = getUsersName(id: self.state!.group!.admin) + "'s Group"
            nameButton.isHidden = true
        } else {
            nameTextField.isHidden = true
            nameLabel.text = self.state!.group?.name
            nameButton.isHidden = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Table Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return state!.group!.users!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "GroupUserTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? GroupUserTableViewCell else{
            fatalError("It messed up")
        }
        
        // Fetches the appropriate song
        let user = state!.group!.users?[indexPath.row]
        
        cell.user.text = getUsersName(id: user!)
        
        // Configure the cell...
        return cell
        
    }
    
    //MARK: Actions
    @IBAction func saveName(_ sender: Any) {
        if (nameButton.titleLabel?.text == "Save Name") {
            nameLabel.text = nameTextField.text
            nameLabel.isHidden = false
            nameTextField.isHidden = true
            nameButton.setTitle("Rename Group", for: .normal)
            state!.group?.name = nameTextField.text
            
            //created NSURL
            let requestURL = URL(string: "http://autocollabservice.com/addgroupname")
            
            //creating NSMutableURLRequest
            let request = NSMutableURLRequest(url: requestURL!)
            
            //creating the post parameter by concatenating the keys and values from text field
            let postParameters = "groupId=\(self.state!.group!.id)" + "&name=" + nameLabel.text!
            
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
            }
            //executing the task
            task.resume()

        } else {
            nameTextField.text = ""
            nameTextField.isHidden = false
            nameLabel.isHidden = true
            nameButton.setTitle("Save Name", for: .normal)
        }
    }
    
    @IBAction func joinActivateButtonPressed(_ sender: Any) {
        if (joinActivateButton.titleLabel?.text == "Join Group") {
            
            // Add user to the group
            
            //created NSURL
            let requestURL = URL(string: "http://autocollabservice.com/addgroupuser")
            
            //creating NSMutableURLRequest
            let request = NSMutableURLRequest(url: requestURL!)
            
            //creating the post parameter by concatenating the keys and values from text field
            let postParameters = "groupId=\(self.state!.group!.id)" + "&userId=" + self.state!.userId! + "&useTop=1"
            
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
            }
            //executing the task
            task.resume()
            
            // Add songs to the user
            if (self.useTopSongsSwitch.isOn == true) {
                RequestWrapper.addUserSongs(songs: self.state!.topSongs, userId: self.state!.userId, groupId: self.state!.group!.id, isTop: 1)
            }
            
            joinActivateButton.setTitle("Leave Group", for: .normal)
            viewPlaylistBtn.isEnabled = true
            useTopSongsSwitch.isEnabled = true
            RequestWrapper.addGroupUser(groupId: self.state!.group!.id, userId: self.state!.userId)
            let useTop = getUseTop(userId: self.state!.userId, groupId: self.state!.group!.id)
            if (useTop == 1) {
                useTopSongsSwitch.isOn = true
            } else {
                useTopSongsSwitch.isOn = false
            }
            state!.group?.users?.append(self.state!.userId)

        }
        
        if (joinActivateButton.titleLabel?.text == "Leave Group") {
            
            deleteGroupUser(userId: self.state!.userId!, groupId: self.state!.group!.id)
            deleteUserFromGroup(userId: self.state!.userId!, groupId: self.state!.group!.id)
            
            joinActivateButton.setTitle("Join Group", for: .normal)
            viewPlaylistBtn.isEnabled = false
            useTopSongsSwitch.isEnabled = false
            if let index = self.state!.group?.users?.index(of: self.state!.userId) {
                self.state!.group?.users?.remove(at: index)
            }
        }
        
        if (joinActivateButton.titleLabel?.text == "Delete Group") {
            //created NSURL
            let requestURL = URL(string: "http://autocollabservice.com/deletegroup")
            
            //creating NSMutableURLRequest
            let request = NSMutableURLRequest(url: requestURL!)
            
            //creating the post parameter by concatenating the keys and values from text field
            let postParameters = "groupId=\(self.state!.group!.id)"
            
            //adding the parameters to request body
            request.httpBody = postParameters.data(using: String.Encoding.utf8)
            
            //setting the method to post
            request.httpMethod = "POST"
            
            let semaphore = DispatchSemaphore(value: 0)
            
            let task = URLSession.shared.dataTask(with: request as URLRequest){
                data, response, error in
                
                if error != nil{
                    print("error is \(String(describing: error))")
                    return;
                }
                
                semaphore.signal()
                
                NSLog("\(String(describing: data))")
            }
            //executing the task
            task.resume()
            _ = semaphore.wait(timeout: .distantFuture)
            
            performSegue(withIdentifier: "groupBackSegue", sender: self)
        }
        
    }
    
    func toggleSwitch(sender:UISwitch!) {
        if (sender.isOn == false) {
            deleteTopSongs(userId: self.state!.userId, groupId: self.state!.group!.id)
            self.useTop = 0
            changeUseTop(userId: self.state!.userId, groupId: self.state!.group!.id, useTop: 0)
        } else {
            // Update to get rid of for loops
            for song in self.state!.topSongs {
                addUserSong(song: song)
            }
            self.useTop = 1
            changeUseTop(userId: self.state!.userId, groupId: self.state!.group!.id, useTop: 1)
        }
        let _ = RequestWrapper.loadSongs(numSongs: 10, lastSong: nil, group: self.state!.group!, session: self.state!.session, reuseNetwork: 0)
    }
    
    @IBAction func copyInviteKey(_ sender: Any) {
        UIPasteboard.general.string = self.state!.group!.inviteKey!
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        if (segue.identifier == "groupBackSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! EventTableViewController
            state?.group = nil
            destinationVC.state = state
        }
        
        if (segue.identifier == "viewPlaylistSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! ViewPlaylistViewController
            destinationVC.state = state
        }
    }
    
    // MARK: HELPERS
    
    func getTopSongs(userId: String, num: Int) -> [Song] {
        var additionalTracks = [Song]()
        let query = "https://api.spotify.com/v1/me/top/tracks?limit=\(num)"
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(self.state!.session.accessToken!)", forHTTPHeaderField: "Authorization")
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
    
    func addUserSong(song: Song) {
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let requestURL = URL(string: "http://autocollabservice.com/addusersong")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        var postParameters = "groupId=\(self.state!.group!.id)" + "&userId=" + self.state!.userId!
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
    
    func deleteGroupUser(userId: String, groupId: Int) {
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/deletegroupuser")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(groupId)" + "&userId=" + userId
        
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
        }
        //executing the task
        task.resume()
    }
    
    func deleteUserFromGroup(userId: String, groupId: Int) {
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/deleteuserfromgroup")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(groupId)" + "&userId=" + userId
        
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
        }
        //executing the task
        task.resume()
    }
    
    func getUsersName(id: String) -> String {
        var name: String?
        
        let query = "https://api.spotify.com/v1/users/" + id
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(self.state!.session.accessToken!)", forHTTPHeaderField: "Authorization")
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
            
        }
        //executing the task
        task.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        return name!
    }
    
    func deleteTopSongs(userId: String, groupId: Int) {
        
        let semaphore = DispatchSemaphore(value: 0)
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/deletetopsongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(groupId)" + "&userId=" + userId
        
        //adding the parameters to request body
        request.httpBody = postParameters.data(using: String.Encoding.utf8)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            semaphore.signal()
            
            if error != nil{
                print("error is \(String(describing: error))")
                return;
            }
            
            NSLog("\(String(describing: data))")
        }
        //executing the task
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
    }
    
    func changeUseTop(userId: String, groupId: Int, useTop: Int) {
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/changeusetop")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(groupId)" + "&userId=" + userId + "&useTop=\(useTop)"
        
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
        }
        //executing the task
        task.resume()
    }
    
    func getUseTop(userId: String, groupId: Int) -> Int {
        
        var useTop: Int?
        let semaphore = DispatchSemaphore(value: 0)
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getusetopsongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(groupId)" + "&userId=" + userId
        
        //adding the parameters to request body
        request.httpBody = postParameters.data(using: String.Encoding.utf8)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            do {
                
                //converting resonse to NSDictionary
                let myJSON =  try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [[Int]]
                
                useTop = myJSON![0][0]
                
                semaphore.signal()
            } catch {
                NSLog("\(error)")
            }
            
            NSLog("\(String(describing: data))")
        }
        //executing the task
        task.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        return useTop!
    }
}
