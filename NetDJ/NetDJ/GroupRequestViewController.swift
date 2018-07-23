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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = Globals.getThemeColor1()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        self.requestTable.delegate = self
        self.requestTable.dataSource = self
        self.requestTable.frame = self.view.frame
        self.requestTable.backgroundColor = Globals.getThemeColor2()
        self.requestTable.rowHeight = 80
        self.requestTable.tableFooterView = UIView()
        
        groups = self.state!.groupRequests
        
        if (groups.count == 0) {
            self.requestTable.isHidden = true
            let emptyLabel = UILabel(frame: self.view.frame)
            emptyLabel.text = "No Requests"
            emptyLabel.textColor = UIColor.gray
            emptyLabel.textAlignment = .center
            self.view.addSubview(emptyLabel)
            
        }
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        rightSwipeGesture.direction = .right
        self.requestTable.addGestureRecognizer(rightSwipeGesture)
        self.view.addGestureRecognizer(rightSwipeGesture)
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
        
        cell.backgroundColor = UIColor.clear
        
        // Configure the cell...
        if (group.name == nil) {
            cell.groupNameLabel.text = Globals.getUsersName(id: group.admin, state: self.state!) + "'s Network"
        } else {
            cell.groupNameLabel.text = group.name
        }
        cell.groupAdminLabel.text = "Admin: " + group.admin
        cell.groupAdminLabel.font = cell.groupAdminLabel.font.withSize(15)
        
        // Add join Button
        let join_Button = UIButton(type: .system)
        join_Button.setTitle("Join", for: .normal)
        join_Button.setTitleColor(Globals.getThemeColor1(), for: .normal)
        join_Button.frame = CGRect(x: self.view.frame.size.width-200, y: 0, width: 100, height: 80)
        join_Button.addTarget(self, action: #selector(joinBtnPressed), for: .touchUpInside)
        join_Button.tag = indexPath.row
        join_Button.backgroundColor = UIColor.white
        cell.addSubview(join_Button)
        
        // Add delete Button
        let delete_Button = UIButton(type: .system)
        delete_Button.setTitle("Delete", for: .normal)
        delete_Button.setTitleColor(UIColor.red, for: .normal)
        delete_Button.frame = CGRect(x: self.view.frame.size.width-100, y: 0, width: 100, height: 80)
        delete_Button.addTarget(self, action: #selector(deleteBtnPressed), for: .touchUpInside)
        delete_Button.tag = indexPath.row
        delete_Button.backgroundColor = Globals.getThemeColor2()
        cell.addSubview(delete_Button)
        
        return cell
    }
    
    func didSwipeRight() {
        self.performSegue(withIdentifier: "groupRequestsBackSegue", sender: self)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "groupRequestsBackSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! NetworkTableViewController
            destinationVC.userShown = true
            destinationVC.state = state
        }
    }
    
    
    // MARK: Helpers
    func joinBtnPressed(sender: UIButton!) {
        let group = self.groups[sender.tag]
        self.groups.remove(at: sender.tag)
        self.requestTable.reloadData()
        
        self.state!.userNetworks[group.id] = group
        
        Globals.addGroupUsers(groupId: group.id, userIds: [self.state!.user.id])
        Globals.addUserDefaults(user: self.state!.user.id, group: group, state: self.state!)
        
        deleteGroupRequest(groupId: group.id)
        
        if (groups.count == 0) {
            self.requestTable.isHidden = true
            let emptyLabel = UILabel(frame: self.view.frame)
            emptyLabel.text = "No Requests"
            emptyLabel.textColor = UIColor.gray
            emptyLabel.textAlignment = .center
            self.view.addSubview(emptyLabel)
            
        }
    }
    
    func deleteBtnPressed(sender: UIButton!) {
        let group = self.groups[sender.tag]
        self.groups.remove(at: sender.tag)
        self.requestTable.reloadData()
        
        deleteGroupRequest(groupId: group.id)
        
        if (groups.count == 0) {
            self.requestTable.isHidden = true
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

}
