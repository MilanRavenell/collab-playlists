//
//  GroupUserTableViewController.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/8/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit
import FacebookCore

class GroupUserTableViewController: UITableViewController {
    
    // MARK: Properties
    var state: State?
    var selectedUser: String?
    var profPicView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Members"
        navigationController?.navigationBar.barTintColor = Globals.getThemeColor1()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        self.tableView.backgroundColor = Globals.getThemeColor2()
        self.tableView.rowHeight = 80
        
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
        return self.state!.group!.users!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "GroupUserTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? GroupUserTableViewCell else{
            fatalError("It messed up")
        }
        
        cell.backgroundColor = UIColor.clear
        
    
        // Fetches the appropriate song
        let user = state!.group!.users?[indexPath.row]
        
        profPicView = UIImageView(frame: CGRect(x: 0, y: 0, width: 80, height: cell.frame.height))
        cell.addSubview(profPicView)
        getProfPicURL(userId: user!, cell: cell)
        
        cell.user.text = Globals.getUsersName(id: user!, state: self.state!)
        cell.user.frame = CGRect(x: cell.user.frame.minX, y: cell.frame.height/2 - 15, width: cell.user.frame.width, height: cell.user.frame.height)
        
        
        
        if (self.state!.group!.admin != self.state!.user.id) {
            // Add delete Button
            let delete_Button = UIButton()
            delete_Button.setTitle("Delete", for: .normal)
            delete_Button.setTitleColor(UIColor.red, for: .normal)
            delete_Button.frame = CGRect(x: self.view.frame.size.width-100, y: 0, width: 100, height: cell.frame.height)
            delete_Button.addTarget(self, action: #selector(deleteBtnPressed), for: .touchUpInside)
            delete_Button.tag = indexPath.row
            cell.addSubview(delete_Button)
        }
        
        // Configure the cell...
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedUser = self.state!.group!.users![indexPath.row]
        //parsing the response
        self.performSegue(withIdentifier: "groupUsersBackSegue", sender: self)
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "groupUsersBackSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! ViewPlaylistViewController
            
            destinationVC.state = state
            destinationVC.otherUser = selectedUser
            if (selectedUser == nil) {
                destinationVC.networkShown = true
            }
        }
        if (segue.identifier == "addUsersSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! FriendSearchViewController
            destinationVC.state = state
            destinationVC.prevController = "GroupUserTable"
        }
    }
    
    // MARK: Helpers
    func didSwipeRight() {
        self.performSegue(withIdentifier: "groupUsersBackSegue", sender: self)
    }
    
    func deleteBtnPressed(sender: UIButton!) {
        let user = self.state!.group!.users![sender.tag]
        self.state!.group!.users!.remove(at: sender.tag)
        self.tableView.reloadData()
        
        Globals.deleteGroupUser(userId: user, groupId: self.state!.group!.id)
        Globals.deleteUserFromGroup(userId: user, groupId: self.state!.group!.id)
    }
    
    func getProfPicURL(userId: String, cell: GroupUserTableViewCell) {
        let fbId = Globals.getFbIds(users: [userId])[0]
        var pic: String?
        
        let params = ["fields": "picture.type(large)"]
        
        let graphrequest = GraphRequest(graphPath: "/" + fbId, parameters: params, accessToken: AccessToken.current, httpMethod: .GET, apiVersion: .defaultVersion)
        
        graphrequest.start({(urlResponse, requestResult) -> Void in
            switch requestResult {
            case .failed(let error):
                print("error:", error)
                break
            case .success(let graphResponse):
                if let responseDictionary = graphResponse.dictionaryValue {
                    pic = ((responseDictionary["picture"] as? [String: AnyObject])?["data"] as? [String: AnyObject])?["url"] as? String
                    
                    if (pic == nil) {
                        self.profPicView.image = UIImage(named: Globals.defaultPic)
                    } else {
                        let url = URL(string: pic!)
                        DispatchQueue.global().async {
                            let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                            DispatchQueue.main.async {
                                self.profPicView.image = UIImage(data: data!)
                            }
                        }
                    }
                }
            }
        })
    }
}
