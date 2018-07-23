//
//  GroupRequestTableViewController.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/9/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class GroupRequestTableViewController: UITableViewController {

    //MARK: Properties
    var groups = [Group]()
    var state: State?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = Globals.getThemeColor1()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        self.tableView.backgroundColor = Globals.getThemeColor2()
        
        self.tableView.rowHeight = 80
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
        return self.groups.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GroupRequestTableViewCell", for: indexPath) as? GroupRequestTableViewCell else{
            fatalError("It messed up")
        }
        let group = self.groups[indexPath.row]
        
        cell.backgroundColor = UIColor.clear

        // Configure the cell...
        cell.groupNameLabel.text = group.name
        cell.groupAdminLabel.text = group.admin
        
        // Add join Button
        let join_Button = UIButton(type: .system)
        join_Button.setTitle("Join", for: .normal)
        join_Button.setTitleColor(Globals.getThemeColor1(), for: .normal)
        join_Button.frame = CGRect(x: self.view.frame.size.width-200, y: 0, width: 100, height: 80)
        join_Button.addTarget(self, action: #selector(joinBtnPressed), for: .touchUpInside)
        join_Button.tag = indexPath.row
        cell.addSubview(join_Button)
        
        // Add delete Button
        let delete_Button = UIButton(type: .system)
        delete_Button.setTitle("Delete", for: .normal)
        delete_Button.setTitleColor(UIColor.red, for: .normal)
        delete_Button.frame = CGRect(x: self.view.frame.size.width-100, y: 0, width: 100, height: 80)
        delete_Button.addTarget(self, action: #selector(deleteBtnPressed), for: .touchUpInside)
        delete_Button.tag = indexPath.row
        cell.addSubview(delete_Button)

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
        self.tableView.reloadData()
        
        self.state!.userNetworks[group.id] = group
        
        Globals.addGroupUsers(groupId: group.id, userIds: [self.state!.user.id])
        Globals.addUserDefaults(user: self.state!.user.id, group: group, session: self.state!.session)
        
        deleteGroupRequest(groupId: group.id)
    }
    
    func deleteBtnPressed(sender: UIButton!) {
        let group = self.groups[sender.tag]
        self.groups.remove(at: sender.tag)
        self.tableView.reloadData()

        deleteGroupRequest(groupId: group.id)
    }
    
    func deleteGroupRequest(groupId: Int) {
        let requestURL = URL(string: "http://autocollabservice.com/deletegrouprequest")
        let request = NSMutableURLRequest(url: requestURL!)
        let postParameters = "userId=" + self.state!.user.id + "&groupId=" + String(groupId)
        
        let _ = Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", isAsync: 0)
    }
}
