//
//  FriendSearchViewController.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/4/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit
import FacebookCore

class FriendSearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate {
    
    //MARK: Properties
    @IBOutlet weak var searchTable: UITableView!
    @IBOutlet weak var selectedTable: UITableView!
    
    var state: State?
    var searchController: UISearchController?
    var totalFriends = UnsafeMutablePointer<[Friend]>.allocate(capacity: 1024)
    var friends = [Friend]()
    var selectedFriends = [Friend]()
    var prevController: String?
    var currentMembers = [String]()
    var spotifyIds = [String]()
    var labelView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Who's in Your Group?"
        // Do any additional setup after loading the view.
        searchTable.dataSource = self
        searchTable.delegate = self
        searchTable.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        searchTable.backgroundColor = Globals.getThemeColor2()
        searchTable.rowHeight = 60
        searchTable.tableFooterView = UIView()
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.tableTapped))
        self.searchTable.backgroundView = UIView()
        self.searchTable.backgroundView?.addGestureRecognizer(gesture)
        
        labelView = UIView(frame: CGRect(x: 0, y: self.view.frame.height-250, width: self.view.frame.width, height: 50))
        labelView.backgroundColor = Globals.getThemeColor1()
        self.view.addSubview(labelView)
        let selectedFriendsLabel = UILabel(frame: CGRect(x: 10, y: 0, width: labelView.frame.width, height: labelView.frame.height))
        selectedFriendsLabel.text = "Selected :"
        selectedFriendsLabel.textColor = UIColor.white
        labelView.addSubview(selectedFriendsLabel)
        
        selectedTable.dataSource = self
        selectedTable.delegate = self
        selectedTable.frame = CGRect(x: 0, y: labelView.frame.maxY, width: self.view.frame.width, height: self.view.frame.height - labelView.frame.maxY)
        selectedTable.backgroundColor = Globals.getThemeColor2()
        selectedTable.rowHeight = 60
        selectedTable.tableFooterView = UIView()
        
        searchTable.reloadData()
        selectedTable.reloadData()

        searchController = UISearchController(searchResultsController: nil)
        
        Globals.getFriends(friends: self.totalFriends)
        if (self.prevController == "GroupUserTable") {
            currentMembers = Globals.getFbIds(users: self.state!.group!.users!)
        }
        
        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            searchController?.searchResultsUpdater = self
            searchController?.delegate = self
            searchController?.searchBar.delegate = self
            searchController?.obscuresBackgroundDuringPresentation = false
            searchController?.searchBar.placeholder = "Search Facebook and Spotify"
            searchController?.hidesNavigationBarDuringPresentation = true
            searchController?.searchBar.tintColor = UIColor.white
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        } else {
            searchController?.hidesNavigationBarDuringPresentation = false
            searchController?.dimsBackgroundDuringPresentation = false
            self.definesPresentationContext = true
            searchController?.searchResultsUpdater = self
            searchController?.delegate = self
            searchController?.searchBar.delegate = self
            searchController?.searchBar.sizeToFit()
            self.searchTable.tableHeaderView = searchController?.searchBar
        }
        definesPresentationContext = true
        
        navigationController?.navigationBar.barTintColor = Globals.getThemeColor1()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.searchController?.searchBar.becomeFirstResponder()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == self.searchTable) {
            return self.friends.count
        }
        return self.selectedFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (tableView == self.searchTable) {
            let cellIdentifier = "FriendSearchTableViewCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? FriendSearchTableViewCell else{
                fatalError("It messed up")
            }
            
            cell.backgroundColor = UIColor.clear
            
            // Fetches the appropriate song
            let friend = self.friends[indexPath.row]
            
            let profPicView = UIImageView(frame: CGRect(x: 0, y: 0, width: 80, height: cell.frame.height))
            print("search: \(cell.frame.height)")
            cell.addSubview(profPicView)
            if (friend.pic != nil) {
                let url = URL(string: friend.pic!)
                DispatchQueue.global().async {
                    let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                    DispatchQueue.main.async {
                        profPicView.image = UIImage(data: data!)
                    }
                }
            } else {
                profPicView.image = UIImage(named: Globals.defaultPic)
            }
            
            cell.nameLabel.text = friend.name
            
            if (self.currentMembers.contains(friend.fbId)) {
                cell.nameLabel.textColor = Globals.getThemeColor1()
            } else {
                cell.nameLabel.textColor = UIColor.black
            }
            
            
            return cell
        } else {
            let cellIdentifier = "SelectedFriendsTableViewCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? SelectedFriendsTableViewCell else{
                fatalError("It messed up")
            }
            
            cell.backgroundColor = UIColor.clear
            
            // Fetches the appropriate song
            let friend = self.selectedFriends[indexPath.row]
            
            let profPicView = UIImageView(frame: CGRect(x: 0, y: 0, width: 80, height: cell.frame.height))
            print("selected: \(cell.frame.height)")
            cell.addSubview(profPicView)
            if (friend.pic != nil) {
                let url = URL(string: friend.pic!)
                DispatchQueue.global().async {
                    let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                    DispatchQueue.main.async {
                        profPicView.image = UIImage(data: data!)
                    }
                }
            } else {
                profPicView.image = UIImage(named: Globals.defaultPic)
            }
            
            
            let delete_Button = UIButton(type: .system)
            delete_Button.setTitle("Delete", for: .normal)
            delete_Button.setTitleColor(UIColor.red, for: .normal)
            delete_Button.frame = CGRect(x: self.view.frame.size.width-100, y: 0, width: 100, height: cell.frame.height)
            delete_Button.addTarget(self, action: #selector(deleteBtnPressed), for: .touchUpInside)
            delete_Button.tag = indexPath.row
            cell.addSubview(delete_Button)
            
            cell.nameLabel.text = friend.name
            
            cell.layoutIfNeeded()
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (tableView == self.searchTable) {
            // Fetches the appropriate song
            let friend = self.friends[indexPath.row]
            
            if (self.currentMembers.contains(friend.fbId)) {
                return
            }
            
            self.selectedFriends.append(friend)
            self.friends[indexPath.row].chosen = true
            
            self.currentMembers.append(friend.fbId)
        }
        self.selectedTable.reloadData()
        self.searchTable.reloadData()
        view.endEditing(true)
        self.searchController?.searchBar.resignFirstResponder()
        self.searchController?.isActive = false
    }
    
    func tableTapped() {
        self.searchController?.searchBar.resignFirstResponder()
        self.searchController?.isActive = false
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if (searchController.searchBar.text! != "") {
            NSLog("updateSearchResults")
            
            self.friends = filterFriends(query: searchController.searchBar.text!)
            self.searchTable.reloadData()
            
            // Search spotfy Id
            let query = "https://api.spotify.com/v1/users/" + searchController.searchBar.text!
            let url = URL(string: query)
            
            if (url == nil) {
                return
            }
            
            let request = NSMutableURLRequest(url: url!)
            request.setValue("Bearer \(self.state!.getAccessToken())", forHTTPHeaderField: "Authorization")
            
            var JSON: [String: AnyObject]?
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                
                if error != nil{
                    print("error is \(String(describing: error))")
                    return;
                }
                
                //parsing the response
                do {
                    //converting resonse to NSDictionary
                    JSON  = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: AnyObject]
                    if (JSON!["error"] == nil) {
                        var name = JSON!["display_name"] as? String
                        if (name == nil) {
                            name = "Name Not Available"
                        }
                        let friend = Friend(name: name!, pic: nil, fbId: "NOID" + (JSON!["id"] as! String))
                        friend?.chosen = false
                        self.friends.insert(friend!, at: 0)
                        DispatchQueue.main.async {
                            self.searchTable.reloadData()
                        }
                    }
                    
                } catch {
                    print("\(error)")
                }
            }
            //executing the
            task.resume()
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        animateSelectedUser(present: false)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        animateSelectedUser(present: true)
    }

    //MARK: Actions
    @IBAction func saveBtnPressed(_ sender: Any) {
        self.spotifyIds = getSpotifyIdsFromFB(friends: self.selectedFriends)
        performSegue(withIdentifier: "saveFriendsToPlaylistSegue", sender: self)
    }
    
    @IBAction func cancelBtnPressed(_ sender: Any) {
        if (self.prevController == "NetworkTable") {
            performSegue(withIdentifier: "findFriendBackSegue", sender: self)
        } else {
            performSegue(withIdentifier: "saveFriendsToPlaylistSegue", sender: self)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "findFriendBackSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! NetworkTableViewController
            state?.group = nil
            destinationVC.state = state
        }
        if (segue.identifier == "saveFriendsToPlaylistSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! ViewPlaylistViewController
            destinationVC.state = state
            if (self.prevController == "NetworkTable") {
                destinationVC.prevController = "FriendSearchWithNewGroup"
            } else {
                destinationVC.prevController = "FriendSearch"
            }
            destinationVC.requestsToSend = self.spotifyIds
        }
    }
    
    
    // MARK: Helpers
    
    func filterFriends(query: String) -> [Friend] {
        let friends = self.totalFriends.pointee.filter({( friend : Friend) -> Bool in
            return friend.name.lowercased().contains(query.lowercased())
        })
        return friends
    }
    
    func deleteBtnPressed(sender: UIButton!) {
        let friend = self.selectedFriends[sender.tag]
        self.selectedFriends.remove(at: sender.tag)
        
        let indx = self.currentMembers.index(where: { (item) -> Bool in
            item == friend.fbId
        })
        if (indx != nil) {
            self.currentMembers.remove(at: indx!)
        }
        self.selectedTable.reloadData()
        self.searchTable.reloadData()
    }
    
    func getSpotifyIdsFromFB(friends: [Friend]) -> [String] {
        
        var fbIds = ""
        
        for friend in friends {
            fbIds += friend.fbId
            fbIds += "///"
        }
        if (friends.count > 0) {
            fbIds.removeLast(3)
        }
        
        let requestURL = URL(string: "http://autocollabservice.com/getspotifyidsfromfb")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "fbIds=" + fbIds
        
        var ids: [String]?
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (response) in
            ids = response as? [String]
        },isAsync: 0)
        
        if (ids != nil) {
            return ids!
        } else {
            return []
        }
    }
    
    func animateSelectedUser(present: Bool) {
        if (present) {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear, animations: {
                self.labelView.frame = CGRect(x: 0, y: self.view.frame.height-500, width: self.view.frame.width, height: 50)
                self.selectedTable.frame = CGRect(x: 0, y: self.labelView.frame.maxY, width: self.view.frame.width, height: self.view.frame.height - self.labelView.frame.maxY)
            }, completion: { (finished) in
                return
            })
        } else {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear, animations: {
                self.labelView.frame = CGRect(x: 0, y: self.view.frame.height-250, width: self.view.frame.width, height: 50)
                self.selectedTable.frame = CGRect(x: 0, y: self.labelView.frame.maxY, width: self.view.frame.width, height: self.view.frame.height - self.labelView.frame.maxY)
            }, completion: { (finished) in
                return
            })
        }
    }
}
