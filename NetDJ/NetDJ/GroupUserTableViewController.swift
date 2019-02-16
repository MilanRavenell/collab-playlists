//
//  GroupUserTableViewController.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/8/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class GroupUserTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: Properties
    @IBOutlet weak var userTable: UITableView!
    var state: State?
    var selectedUser: User?
    var totalEditSwitch: UISwitch!
    var canEditSwitches = [UISwitch]()
    var usersCanEdit = [String]()
    var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        state?.groupUsersVC = self
        
        self.userTable.delegate = self
        self.userTable.dataSource = self
        self.userTable.tableFooterView = UIView()
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator?.center = self.view.center
        activityIndicator?.startAnimating()
        self.view.addSubview(activityIndicator!)
        
        if let usersLoaded = self.state!.group?.usersLoaded, usersLoaded {
            usersDidLoad()
        }
        
        if Globals.dedicatedServer {
            let totalEditSwitchView = UIView(frame: CGRect(x: 0, y: navigationController!.navigationBar.frame.maxY, width: self.view.frame.width, height: 60))
            totalEditSwitchView.backgroundColor = UIColor.white
            self.view.addSubview(totalEditSwitchView)
            
            totalEditSwitch = UISwitch(frame: CGRect(x: totalEditSwitchView.frame.maxX - 60, y: totalEditSwitchView.bounds.midY - 5, width: 60, height: totalEditSwitchView.frame.height))
            totalEditSwitch.addTarget(self, action: #selector(totalCanEditSwitchToggled), for: .valueChanged)
            totalEditSwitchView.addSubview(totalEditSwitch)
            
            self.userTable.frame = CGRect(x: 0, y: totalEditSwitchView.frame.maxY, width: self.view.frame.width, height: self.view.frame.height)

        } else {
            self.userTable.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        }
        
        self.title = "Members"
        
        self.userTable.rowHeight = 60
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        rightSwipeGesture.direction = .right
        self.userTable.addGestureRecognizer(rightSwipeGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let userDefaults = UserDefaults.standard
        
        if userDefaults.object(forKey: "DidGroupUsersAlert") == nil {
            // User is logged in, use 'accessToken' here.
            let alert = UIAlertController(title: "View Your Friends' Queues", message: "Tap on your friends to see what's currently on their queue", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Okay!", style: .cancel, handler: nil))
            
            self.present(alert, animated: true)
        
            let requestedFbData = NSKeyedArchiver.archivedData(withRootObject: true)
            userDefaults.set(requestedFbData, forKey: "DidGroupUsersAlert")
            userDefaults.synchronize()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if let users = self.state!.group?.users {
            return users.count
        } else {
            return 0
        }
        
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "GroupUserTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? GroupUserTableViewCell else{
            fatalError("It messed up")
        }
        
        cell.backgroundColor = UIColor.clear
        
    
        // Fetches the appropriate song
        if let user = state!.group?.users[indexPath.row] {
            cell.name.text = user.name
            cell.pic.image = user.pic
        }
        
        if Globals.dedicatedServer {
            let canEditSwitch = UISwitch(frame: CGRect(x: self.view.frame.size.width - 60, y: cell.contentView.frame.midY - 5, width: 60, height: cell.contentView.frame.height))
            canEditSwitch.tag = indexPath.row
            canEditSwitch.addTarget(self, action: #selector(canEditSwitchToggled), for: .valueChanged)
            cell.contentView.addSubview(canEditSwitch)
            self.canEditSwitches.append(canEditSwitch)
        }
        
        // Configure the cell...
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        selectedUser = self.state!.group?.users[indexPath.row]
        if selectedUser?.id != self.state!.user.id {
            self.performSegue(withIdentifier: "viewUsersSongsSegue", sender: self)
        }
    }
    
    // MARK: - Action
    
    @IBAction func unwindToGroupUser(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? FriendSearchViewController {
            if let id = self.state!.group?.id {
                Globals.createGroupRequests(userIds: sourceViewController.spotifyIds, groupId: id, inviter: self.state!.user.id)
            }
        }
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "viewUsersSongsSegue") {
            let destinationVC = segue.destination as! SongsViewController
            
            destinationVC.state = state
            destinationVC.user = selectedUser
        }
        if (segue.identifier == "addUsersSegue") {
            let destinationVC = segue.destination as! FriendSearchViewController
            destinationVC.state = state
            destinationVC.prevController = "GroupUserTable"
        }
    }
    
    // MARK: - Helpers
    func didSwipeRight() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func deleteBtnPressed(sender: UIButton!) {
        if let user = self.state!.group?.users[sender.tag] {
            self.state!.group!.users.remove(at: sender.tag)
            self.userTable.reloadData()
            
            if let id = self.state!.group?.id {
                Globals.deleteGroupUser(userId: user.id, groupId: id)
                Globals.deleteUserFromGroup(userId: user.id, groupId: id)
            }
        }
    }
    
    func totalCanEditSwitchToggled(sender: UISwitch!) {
        var i = 0
        if let users = self.state!.group?.users {
            for user in users {
                if (sender.isOn && !self.usersCanEdit.contains(user.id)) {
                    self.usersCanEdit.append(user.id)
                    self.canEditSwitches[i].setOn(true, animated: true)
                }
                if (!sender.isOn && self.usersCanEdit.contains(user.id)) {
                    self.usersCanEdit.remove(at: self.usersCanEdit.index(of: user.id)!)
                    self.canEditSwitches[i].setOn(false, animated: true)
                }
                i += 1
            }
        }
    }
    
    func canEditSwitchToggled(sender: UISwitch!) {
        if let user = self.state!.group?.users[sender.tag] {
            if (sender.isOn) {
                self.usersCanEdit.append(user.id)
            } else {
                self.usersCanEdit.remove(at: self.usersCanEdit.index(of: user.id)!)
            }
            print(self.usersCanEdit)
        }
    }
    
    func usersDidLoad() {
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator?.stopAnimating()
            self?.userTable.isHidden = false
            self?.userTable.reloadData()
        }
    }
}
