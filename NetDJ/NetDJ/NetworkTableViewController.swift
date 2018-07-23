//
//  NetworkTableViewController.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/15/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import FBSDKLoginKit

class NetworkTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    //MARK: Properties
    @IBOutlet weak var networkTable: UITableView!
    var groups = [Group]()
    var state: State?
    var selectedGroup: Group?
    var userView: UserView!
    var dimView: UIView!
    var dismiss: UITapGestureRecognizer!
    var userShown = false
    @IBOutlet weak var addBtn: UIBarButtonItem!
    var accessToken = AccessToken.current
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Your Networks"
        
        if ((networkTable) != nil) {
            networkTable.dataSource = self
            networkTable.delegate = self
            networkTable.rowHeight = 90
            networkTable.frame = self.view.frame
        }
        
        self.groups = Array(self.state!.userNetworks.values)
        self.networkTable.reloadData()
        
        self.networkTable.backgroundColor = Globals.getThemeColor2()
        
        navigationController?.navigationBar.barTintColor = Globals.getThemeColor1()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        dimView = UIView(frame: self.view.frame)
        dimView.isHidden = true
        dismiss = UITapGestureRecognizer(target: self, action: #selector(self.triggerDismiss))
        dimView.addGestureRecognizer(dismiss)
        self.view.addSubview(dimView)
        
        userView = UserView(frame: CGRect(x: 0 - 2 * self.view.frame.width/3, y: 0, width: 2 * self.view.frame.width/3, height: self.view.frame.height), parent: self)
        userView.backgroundColor = Globals.getThemeColor2()
        self.view.addSubview(userView)
        
        if (userShown) {
            dimView.isHidden = false
            dimView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            userView.frame =  CGRect(x: 0, y: 0, width: 2 * self.view.frame.width/3, height: self.view.frame.height)
        }
        
        getUserGroupRequests()
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didRightSwipe))
        rightSwipeGesture.direction = .right
        self.networkTable.addGestureRecognizer(rightSwipeGesture)
        
        let userLeftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(triggerDismiss))
        userLeftSwipeGesture.direction = .left
        self.userView.addGestureRecognizer(userLeftSwipeGesture)
        
        let dimLeftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(triggerDismiss))
        dimLeftSwipeGesture.direction = .left
        self.dimView.addGestureRecognizer(dimLeftSwipeGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let userDefaults = UserDefaults.standard
        
        if userDefaults.object(forKey: "DidRequestFacebookLogin") == nil {
            if (AccessToken.current == nil) {
                // User is logged in, use 'accessToken' here.
                let alert = UIAlertController(title: "You are not logged into a Facebook Account", message: "We recommend that you log into your Facebook account to make it easier to add your friends", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Log In", style: .default, handler: facebookLogin))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                self.present(alert, animated: true)
                
                
                let requestedFbData = NSKeyedArchiver.archivedData(withRootObject: true)
                userDefaults.set(requestedFbData, forKey: "DidRequestFacebookLogin")
                userDefaults.synchronize()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NetworkTableViewCell", for: indexPath) as? NetworkTableViewCell else {
            fatalError("It messed up")
        }
        cell.backgroundColor = UIColor.clear
        
        let group = self.groups[indexPath.row]
        let name = Globals.getUsersName(id: group.admin, state: self.state!)
        
        // Configure the cell...
        if (group.name == nil || group.name == "") {
            cell.name.text = name + "'s Network"
        } else {
            cell.name.text = group.name
        }
        
        cell.admin.text = "Admin: " + name
        cell.admin.font = cell.admin.font.withSize(15)
        
        let networkPicView = UIImageView(frame: CGRect(x: 10, y: 10, width: 80, height: cell.frame.height - 20))
        cell.addSubview(networkPicView)
        networkPicView.image = group.pic.pointee
        DispatchQueue.global().async {
            if (group.picURL != nil) {
                let url = URL(string: group.picURL!)
                if let data = try? Data(contentsOf: url!) {
                    DispatchQueue.main.async {
                        networkPicView.image = UIImage(data: data)!
                    }
                }
            }
        }
        
        networkPicView.contentMode = .scaleAspectFill
        
        if (group.id == self.state?.currentActiveGroup) {
            cell.name.textColor = Globals.getThemeColor1()
            cell.admin.textColor = Globals.getThemeColor1()
        } else {
            cell.name.textColor = UIColor.black
            cell.admin.textColor = UIColor.black
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        state!.group = groups[indexPath.row]
        //parsing the response
        self.performSegue(withIdentifier: "viewPlaylistSegue", sender: self)
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
    
    func triggerDismiss() {
        presentUserView(present: false)
    }
    
    func didRightSwipe() {
        presentUserView(present: true)
    }
    
    //MARK: Actions
    
    @IBAction func addGroupPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "findFriendsSegue", sender: self)
    }
    
    
    @IBAction func userBtnPressed(_ sender: Any) {
        presentUserView(present: !self.userShown)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        
        if (segue.identifier == "viewPlaylistSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! ViewPlaylistViewController
            destinationVC.state = state
        }
        if (segue.identifier == "searchGroupSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! GroupSearchViewController
            destinationVC.state = state
        }
        if (segue.identifier == "findFriendsSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! FriendSearchViewController
            destinationVC.state = state
            destinationVC.prevController = "NetworkTable"
        }
        if (segue.identifier == "defaultSongsSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! SongsViewController
            destinationVC.prevController = "User"
            self.state?.group = Group(name: nil, admin: self.state!.user.id, id: -1, picURL: nil, users: nil, inviteKey: nil)
            destinationVC.state = state
        }
        if (segue.identifier == "defaultPlaylistsSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! UserPlaylistsTableViewController
            destinationVC.prevController = "User"
            self.state?.group = Group(name: nil, admin: self.state!.user.id, id: -1, picURL: nil, users: nil, inviteKey: nil)
            destinationVC.state = state
        }
        if (segue.identifier == "viewGroupRequestsSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! GroupRequestViewController
            destinationVC.state = state
        }
    }
    
    func facebookLogin(alert: UIAlertAction!) {
        Globals.logIntoFacebook(viewController: self, userId: self.state!.user.id)
    }
    
    func getUserGroupRequests() {
        
        var groupRequests = [Int]()
        let requestURL = URL(string: "http://autocollabservice.com/getgrouprequests")
        let request = NSMutableURLRequest(url: requestURL!)
        let postParameters = "userId=" + self.state!.user.id
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (response) in
            print("start")
            let groups = response as? [[AnyObject]]
            
            if (groups == nil) {
                return
            }
            for group in groups! {
                let id = group[1] as! Int
                groupRequests.append(id)
            }
            
            DispatchQueue.global().async {
                self.state!.groupRequests = Globals.getGroupsById(ids: groupRequests)
                DispatchQueue.main.async {
                    self.userView.viewRequests.setTitle("View Network Requests(" + String(self.state!.groupRequests.count) + ")", for: .normal)
                }
            }
            
            
            
            print("Done")
        }, isAsync: 1)
    }
    
    func presentUserView(present: Bool) {
        if (present) {
            self.dimView.isHidden = false
            UIView.animate(withDuration: 0.15, animations: {
                self.dimView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            })
            
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveLinear, animations: {
                self.userView?.frame = CGRect(x: 0, y: 0, width: 2 * self.view.frame.width/3, height: self.view.frame.height)
            }, completion: { (finished) in
                self.userShown = true
            })
        } else {
            UIView.animate(withDuration: 0.15, animations: {
                self.dimView.backgroundColor = UIColor.clear
            })
            self.dimView.isHidden = true
            
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveLinear, animations: {
                self.userView?.frame = CGRect(x: 0 - 2 * self.view.frame.width/3, y: 0, width: 2 * self.view.frame.width/3, height: self.view.frame.height)
            }, completion: { (finished) in
                self.userShown = false
            })
        }
    }
    
    func facebookLogin() {
        if (AccessToken.current == nil) {
            Globals.logIntoFacebook(viewController: self, userId: self.state!.user.id)
        } else {
            LoginManager().logOut()
            self.userView.facebookBtn.setTitle("Connect Facebook Account", for: .normal)
        }
    }

}
