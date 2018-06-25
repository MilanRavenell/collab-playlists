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
    var state: State?
    var selectedGroup: Group?

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
        
        let (groupId, inviteKey) = createGroup()
        RequestWrapper.addGroupUser(groupId: groupId, userId: self.state!.userId)
        self.selectedGroup = Group(name: nil, admin: self.state!.userId, id: groupId, activated: false, users: [self.state!.userId], inviteKey: inviteKey)
        
        NSLog("gettingTopSongs")

        RequestWrapper.addUserSongs(songs: self.state!.topSongs, userId: self.state!.userId, groupId: self.selectedGroup!.id, isTop: 1)
        
        performSegue(withIdentifier: "viewGroups", sender: self)
        
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)

        if (segue.identifier == "viewGroups") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! GroupViewController
            state!.group = selectedGroup!
            destinationVC.state = state
        }
        if (segue.identifier == "searchGroupSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! GroupSearchViewController
            destinationVC.state = state
        }
        
    }
    
    // MARK: Helpers
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
            
            NSLog("\(String(describing: data))")
        }
        //executing the task
        task.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        return name!
    }
    
    func getGroups() -> [Group] {
        
        var groups = [Group]()
        
        let ids = getUserGroups()
        
        if (ids == "") {
            return []
        }
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getgroups")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        let postParameters = "method=id&groupIds=" + ids
        
        let response = RequestWrapper.sendRequest(request: request, postParameters: postParameters, method: "POST", isAsync: 0) as! [[String: AnyObject]]
        
        for group in response {
            NSLog("group")
            let name = group["name"] as? String
            let admin = group["admin"] as! String
            let id = group["id"] as! Int
            let activated = group["activated"] as! Bool
            let inviteKey = group["invite_key"] as! String
            let newGroup = Group(name: name, admin: admin, id: id, activated: activated, users:[], inviteKey: inviteKey)
            groups.append(newGroup!)
        }
        
        for group in groups {
            group.users = RequestWrapper.getGroupUsers(id: group.id)
        }
        
        return groups
    }
    
    func getUserGroups() -> String {
        var ids = [Int]()
        
        //created NSURL
        var requestURL = URL(string: "http://autocollabservice.com/getusergroups")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        let postParameters = "userId=" + self.state!.userId
        
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
            
            NSLog("\(String(describing: data))")
            
            //parsing the response
            do {
                //converting resonse to NSDictionary
                let myJSON =  try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: AnyObject]
                
                //parsing the json
                if let results = myJSON {
                    ids = results["groups"] as! [Int]
                }
            } catch {
                NSLog("\(error)")
            }
            semaphore.signal()
            
        }
        //executing the task
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        
        var ids_str = ""
        
        for id in ids {
            ids_str += String(id)
            ids_str += ","
        }
        
        if ids_str.count > 0 {
            ids_str.removeLast()
        }
        
        return ids_str
    }
    
    func createGroup() -> (Int, String) {
        
        var groupId: Int?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let requestURL = URL(string: "http://autocollabservice.com/creategroup")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        let inviteKey = randomString(length: 15)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "admin=" + self.state!.userId + "&inviteKey=" + inviteKey
        
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
                    groupId = parseJSON["groupId"] as? Int
                }
            } catch {
                NSLog("\(error)")
            }
            semaphore.signal()
            
        }
        //executing the task
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        
        return (groupId!, inviteKey)
    }
    
    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
}
