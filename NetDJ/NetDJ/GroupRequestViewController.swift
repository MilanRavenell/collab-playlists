//
//  GroupRequestViewController.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/16/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class GroupRequestViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    //MARK: Properties
    @IBOutlet weak var requestTable: UITableView!
    var groups = [Group]()
    var state: State?
    var alertView: UIView!
    var alertLabel: UILabel!
    var networkTableVC: NetworkTableViewController!
    var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Your Network Requests"

        self.requestTable.delegate = self
        self.requestTable.dataSource = self
        self.requestTable.frame = self.view.frame
        self.requestTable.backgroundColor = Globals.getThemeColor2()
        self.requestTable.rowHeight = 80
        self.requestTable.tableFooterView = UIView()
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.center = self.view.center
        self.view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        DispatchQueue.global().async { [weak self] in
            self?.getUserGroupRequests()
        }
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        rightSwipeGesture.direction = .right
        self.requestTable.addGestureRecognizer(rightSwipeGesture)
        self.view.addGestureRecognizer(rightSwipeGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
        return self.groups.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GroupRequestTableViewCell", for: indexPath) as? GroupRequestTableViewCell else{
            fatalError("It messed up")
        }
        let group = self.groups[indexPath.row]
        let inviter = self.state!.inviters[indexPath.row]
        
        cell.backgroundColor = UIColor.clear
        
        // Configure the cell...
        cell.groupNameLabel.text = group.name
        cell.groupAdminLabel.text = "Invited By: " + Globals.getUsersName(id: inviter, state: self.state!)!
        cell.groupAdminLabel.font = cell.groupAdminLabel.font.withSize(15)
        
        let networkPicView = UIImageView(frame: CGRect(x: 10, y: 10, width: 80, height: cell.frame.height - 20))
        cell.addSubview(networkPicView)
        group.assignPicToView(imageView: networkPicView)
        
        cell.groupNameLabel.frame = CGRect(x: cell.groupNameLabel.frame.minX, y: cell.groupNameLabel.frame.minY, width: cell.contentView.bounds.width - 100, height: cell.groupNameLabel.frame.height)
        cell.groupAdminLabel.frame = CGRect(x: cell.groupAdminLabel.frame.minX, y: cell.groupAdminLabel.frame.minY, width: cell.contentView.bounds.width - 100, height: cell.groupAdminLabel.frame.height)
        
        
        // Add join Button
        let join_Button = UIButton(type: .system)
        join_Button.setTitle("+", for: .normal)
        join_Button.titleLabel?.font = join_Button.titleLabel?.font.withSize(30)
        join_Button.setTitleColor(Globals.getThemeColor1(), for: .normal)
        join_Button.frame = CGRect(x: self.view.frame.size.width-120, y: 0, width: 60, height: 80)
        join_Button.addTarget(self, action: #selector(joinBtnPressed), for: .touchUpInside)
        join_Button.tag = indexPath.row
        cell.addSubview(join_Button)
        
        // Add delete Button
        let delete_Button = UIButton(type: .system)
        delete_Button.setTitle("x", for: .normal)
        delete_Button.titleLabel?.font = delete_Button.titleLabel?.font.withSize(25)
        delete_Button.setTitleColor(UIColor.red, for: .normal)
        delete_Button.frame = CGRect(x: self.view.frame.size.width-60, y: 0, width: 60, height: 80)
        delete_Button.addTarget(self, action: #selector(deleteBtnPressed), for: .touchUpInside)
        delete_Button.tag = indexPath.row
        cell.addSubview(delete_Button)
        
        return cell
    }
    
    func didSwipeRight() {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    }
    
    
    // MARK: Helpers
    func joinBtnPressed(sender: UIButton!) {
        Globals.showAlert(text: "Joined!", view: self.view)
        let group = self.groups[sender.tag]
        self.groups.remove(at: sender.tag)
        self.requestTable.reloadData()
        deleteGroupRequest(groupId: group.id)
        
        self.state!.userNetworks[group.id] = group
        networkTableVC.groups = Array(self.state!.userNetworks.values)
        networkTableVC.networkTable.reloadData()
        
        DispatchQueue.global().async { [weak self] in
            if let state = self?.state {
                Globals.addGroupUsers(groupId: group.id, userIds: [state.user.id])
                Globals.addUserDefaults(user: state.user, group: group, state: state)
                
                group.isJoining = true
                Globals.updateNetwork(group: group, state: state)
                group.songs = [Song]()
                Globals.generateSongs(group: group, numSongs: 10, lastSong: nil, state: state, viewPlaylistVC: nil)
                Globals.addPlaylistSongs(songs: group.songs!, groupId: group.id, userId: state.user.id)
                if group.songs!.count > 0 {
                    group.songs = [group.songs![0]]
                }
                group.isJoining = false
                self?.state!.viewPlaylistVC?.networkSetup()
                state.archiveGroups()
            }
        }
        
        if (groups.count == 0) {
            self.requestTable.reloadData()
            let emptyLabel = UILabel(frame: self.view.frame)
            emptyLabel.text = "No Requests"
            emptyLabel.textColor = UIColor.gray
            emptyLabel.textAlignment = .center
            self.view.addSubview(emptyLabel)
            
        }
    }
    
    func deleteBtnPressed(sender: UIButton!) {
        Globals.showAlert(text: "Deleted!", view: self.view)
        let group = self.groups[sender.tag]
        self.groups.remove(at: sender.tag)
        self.requestTable.reloadData()
        
        deleteGroupRequest(groupId: group.id)
        
        
        if (groups.count == 0) {
            let emptyLabel = UILabel(frame: self.view.frame)
            emptyLabel.text = "No Requests"
            emptyLabel.textColor = UIColor.gray
            emptyLabel.textAlignment = .center
            self.view.addSubview(emptyLabel)
            
        }
    }
    
    func deleteGroupRequest(groupId: Int) {
        let requestURL = URL(string: "http://autocollabservice.com/deletegrouprequest")
        let request = NSMutableURLRequest(url: requestURL!)
        let postParameters = "userId=" + self.state!.user.id + "&groupId=" + String(groupId)
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {_ in}, isAsync: 0)
    }
    
    func getUserGroupRequests() {
        
        var groupRequests = [Int]()
        let requestURL = URL(string: "http://autocollabservice.com/getgrouprequests")
        let request = NSMutableURLRequest(url: requestURL!)
        let postParameters = "userId=" + self.state!.user.id
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { [weak self] (response) in
            print("start")
            let groups = response as? [[AnyObject]]
            
            if (groups == nil) {
                return
            }
            for group in groups! {
                let id = group[1] as! Int
                let inviter = group[2] as! String
                groupRequests.append(id)
                self?.state!.inviters.append(inviter)
            }
        }, isAsync: 0)
        
        self.groups = Globals.getGroupsById(ids: groupRequests, state: self.state!)
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator.stopAnimating()
            self?.requestTable.reloadData()
            if self?.groups.count == 0 {
                if let view = self?.view {
                    let emptyLabel = UILabel(frame: view.frame)
                    emptyLabel.text = "No Requests"
                    emptyLabel.textColor = UIColor.gray
                    emptyLabel.textAlignment = .center
                    self?.view.addSubview(emptyLabel)
                }
            }
        }
    }
}
